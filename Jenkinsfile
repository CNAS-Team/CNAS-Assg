def appImage

pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 45, unit: 'MINUTES')
        buildDiscarder(
            logRotator(
                numToKeepStr: '20',
                artifactNumToKeepStr: '10'
            )
        )
        skipDefaultCheckout(true)
    }

    environment {
        DOCKER_REGISTRY_CREDENTIALS_ID = 'docker-hub-credentials'
        DOCKER_IMAGE_NAME = 'sinoceratops/cnas-php-app'

        KUBERNETES_CREDENTIALS_ID = 'kubeconfig-cluster-secret'

        DB_CREDENTIALS_ID = 'cnas-db-credentials'
        MYSQL_ROOT_PASSWORD_CREDENTIALS_ID = 'cnas-mysql-root-password'
        REDIS_PASSWORD_CREDENTIALS_ID = 'cnas-redis-password'

        // The Jenkins credential ID where you stored your Cosign private key
        COSIGN_KEY_CREDENTIALS_ID = 'cosign-private-key'

        K8S_NAMESPACE = 'cnas'
        DEPLOYMENT_NAME = 'php-app'

        DEPLOY_STARTED = 'false'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_SHA}"

                    currentBuild.displayName =
                        "#${env.BUILD_NUMBER} ${env.GIT_SHA}"
                }

                sh '''
                    set -eu
                    test -z "$(git status --porcelain)"
                '''
            }
        }

        stage('Deep Secret Scan (Gitleaks)') {
            steps {
                echo "=== Scanning Git History for Leaked Secrets ==="
                sh '''
                    docker run --rm \
                      -v "$WORKSPACE:/path" \
                      zricethezav/gitleaks:latest detect --source="/path" -v
                '''
            }
        }

        stage('Validate Source and Configuration') {
            steps {
                sh '''
                    set -eu

                    echo "Jenkins workspace:"
                    echo "$WORKSPACE"

                    echo "Checking repository contents inside Jenkins:"
                    test -d php-app
                    test -d tests/php
                    test -f tests/php/run.php

                    docker run --rm \
                      --volumes-from "$HOSTNAME" \
                      -w "$WORKSPACE" \
                      php:8.2-cli-alpine \
                      sh -ec 'find php-app tests/php -type f -name "*.php" -exec php -l {} \\;'

                    docker run --rm \
                      --volumes-from "$HOSTNAME" \
                      -w "$WORKSPACE" \
                      php:8.2-cli-alpine \
                      php tests/php/run.php

                    kubectl kustomize k8s > rendered-kubernetes.yaml
                '''
            }
        }

        stage('SAST Code Scanning (Semgrep)') {
            steps {
                echo "=== Scanning PHP Source Code for Vulnerabilities ==="
                sh '''
                    docker run --rm \
                      -v "$WORKSPACE:/src" \
                      returntocorp/semgrep semgrep scan --config=p/php /src
                '''
            }
        }

        stage('Repository Security Scan (Trivy)') {
            steps {
                sh '''
                    set -eu

                    docker run --rm \
                    --volumes-from "$HOSTNAME" \
                    -w "$WORKSPACE" \
                    aquasec/trivy:latest \
                    fs \
                    --exit-code 1 \
                    --severity HIGH,CRITICAL \
                    --scanners vuln,misconfig,secret \
                    --skip-files tests/k8s/policy-deny-latest.yaml \
                    --skip-files tests/k8s/policy-disallow-privileged.yaml \
                    --skip-files tests/k8s/policy-require-nonroot.yaml \
                    --skip-files tests/k8s/policy-require-resources.yaml \
                    --no-progress \
                    .
                '''
            }
        }

        stage('Build and Verify Image') {
            steps {
                script {
                    /*
                     * --pull obtains the newest version of the configured
                     * base image.
                     *
                     * The final "." is the Docker build context.
                     */
                    appImage = docker.build(
                        "${env.DOCKER_IMAGE_NAME}:${env.IMAGE_TAG}",
                        '--pull .'
                    )
                }

                sh '''
                    set -eu

                    echo "Checking runtime image:"
                    echo "$DOCKER_IMAGE_NAME:$IMAGE_TAG"

                    docker image inspect \
                      "$DOCKER_IMAGE_NAME:$IMAGE_TAG" \
                      > /dev/null

                    # Confirm required PHP extensions are present in the image.
                    docker run --rm \
                      "$DOCKER_IMAGE_NAME:$IMAGE_TAG" \
                      php -r '
                        $required = [
                            "mysqli",
                            "redis"
                        ];

                        foreach ($required as $extension) {
                            if (!extension_loaded($extension)) {
                                fwrite(
                                    STDERR,
                                    "Missing PHP extension: {$extension}\\n"
                                );
                                exit(1);
                            }

                            echo "PASS: {$extension} is loaded\\n";
                        }
                      '
                '''
            }
        }

        stage('Image Security and SBOM') {
    steps {
        sh '''
            set -eu

            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              aquasec/trivy:latest \
              image \
              --exit-code 1 \
              --severity HIGH,CRITICAL \
              --ignore-unfixed \
              --no-progress \
              "$DOCKER_IMAGE_NAME:$IMAGE_TAG"

            docker run --rm \
              --volumes-from "$HOSTNAME" \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -w "$WORKSPACE" \
              aquasec/trivy:latest \
              image \
              --format cyclonedx \
              --output sbom.cdx.json \
              "$DOCKER_IMAGE_NAME:$IMAGE_TAG"
        '''

        archiveArtifacts(
            artifacts: 'sbom.cdx.json,rendered-kubernetes.yaml',
            fingerprint: true
        )
    }
}

        stage('Push Immutable Image') {
            steps {
                script {
                    docker.withRegistry(
                        '',
                        env.DOCKER_REGISTRY_CREDENTIALS_ID
                    ) {
                        appImage.push()
                    }
                }
            }
        }

        stage('Sign Container Image (Cosign)') {
            steps {
                echo "=== Cryptographically Signing Container Image ==="
                
                // Dynamically download Cosign to bypass Windows container limitations
                sh '''
                    curl -sL -o cosign "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
                    chmod +x cosign
                '''

                // Pull the private key from Jenkins credentials and sign the image
                withCredentials([
                    file(credentialsId: env.COSIGN_KEY_CREDENTIALS_ID, variable: 'COSIGN_KEY'),
                    ]) {
                    script {
                        docker.withRegistry('', env.DOCKER_REGISTRY_CREDENTIALS_ID) {
                            sh 'COSIGN_PASSWORD="" ./cosign sign --key \$COSIGN_KEY -y ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}'
                        }
                    }
                }
            }
        }

        stage('Deploy and Verify') {
            steps {
                withKubeConfig([
                    credentialsId: env.KUBERNETES_CREDENTIALS_ID
                ]) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: env.DB_CREDENTIALS_ID,
                            usernameVariable: 'CNAS_DB_USER',
                            passwordVariable: 'CNAS_DB_PASSWORD'
                        ),
                        string(
                            credentialsId:
                                env.MYSQL_ROOT_PASSWORD_CREDENTIALS_ID,
                            variable: 'CNAS_MYSQL_ROOT_PASSWORD'
                        ),
                        string(
                            credentialsId:
                                env.REDIS_PASSWORD_CREDENTIALS_ID,
                            variable: 'CNAS_REDIS_PASSWORD'
                        )
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            kubectl create secret generic cnas-secret \
                              --namespace "$K8S_NAMESPACE" \
                              --from-literal=DB_USER="$CNAS_DB_USER" \
                              --from-literal=DB_PASSWORD="$CNAS_DB_PASSWORD" \
                              --from-literal=MYSQL_ROOT_PASSWORD="$CNAS_MYSQL_ROOT_PASSWORD" \
                              --from-literal=REDIS_PASSWORD="$CNAS_REDIS_PASSWORD" \
                              --dry-run=client \
                              -o yaml \
                              | kubectl apply -f -

                            set -x

                            kubectl get secret cnas-secret \
                              -n "$K8S_NAMESPACE" \
                              -o name
                        '''
                    }

                    script {
                        env.DEPLOY_STARTED = 'true'

                        sh '''
                            set -eu
                            rm -rf ci-runtime
                            mkdir -p ci-runtime
                        '''

                        writeFile(
                            file: 'ci-runtime/kustomization.yaml',
                            text: """apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../k8s
images:
  - name: sinoceratops/cnas-php-app
    newName: ${env.DOCKER_IMAGE_NAME}
    newTag: ${env.IMAGE_TAG}
"""
                        )
                    }

                    sh '''
                        set -eu

                        kubectl apply \
                          -k ci-runtime

                        kubectl wait \
                          --for=condition=complete \
                          job/db-migration-v2 \
                          -n "$K8S_NAMESPACE" \
                          --timeout=5m

                        kubectl annotate \
                          deployment "$DEPLOYMENT_NAME" \
                          -n "$K8S_NAMESPACE" \
                          kubernetes.io/change-cause="git=$GIT_SHA image=$DOCKER_IMAGE_NAME:$IMAGE_TAG" \
                          cnas.assignment/git-sha="$GIT_SHA" \
                          cnas.assignment/image="$DOCKER_IMAGE_NAME:$IMAGE_TAG" \
                          --overwrite

                        kubectl rollout status \
                          deployment/"$DEPLOYMENT_NAME" \
                          -n "$K8S_NAMESPACE" \
                          --timeout=5m

                        kubectl wait \
                          --for=condition=Ready \
                          pod \
                          -l app=php-app \
                          -n "$K8S_NAMESPACE" \
                          --timeout=180s

                        bash scripts/ci-smoke-test.sh

                        kubectl get \
                          pods,svc,deployment,hpa,pdb \
                          -n "$K8S_NAMESPACE" \
                          -o wide

                        DEPLOYED_IMAGE="$(
                            kubectl get deployment "$DEPLOYMENT_NAME" \
                              -n "$K8S_NAMESPACE" \
                              -o jsonpath='{.spec.template.spec.containers[?(@.name=="php-app")].image}'
                        )"

                        echo "Expected image: $DOCKER_IMAGE_NAME:$IMAGE_TAG"
                        echo "Deployed image: $DEPLOYED_IMAGE"

                        test \
                          "$DEPLOYED_IMAGE" = \
                          "$DOCKER_IMAGE_NAME:$IMAGE_TAG"
                    '''
                }
            }
        }
    }

    post {
        failure {
            script {
                if (env.DEPLOY_STARTED == 'true') {
                    withKubeConfig([
                        credentialsId:
                            env.KUBERNETES_CREDENTIALS_ID
                    ]) {
                        sh '''
                            kubectl rollout undo \
                              deployment/"$DEPLOYMENT_NAME" \
                              -n "$K8S_NAMESPACE" \
                              || true

                            kubectl rollout status \
                              deployment/"$DEPLOYMENT_NAME" \
                              -n "$K8S_NAMESPACE" \
                              --timeout=3m \
                              || true
                        '''
                    }
                } else {
                    echo(
                        'Failure occurred before deployment; ' +
                        'no rollback was attempted.'
                    )
                }
            }
        }

        always {
            archiveArtifacts(
                artifacts:
                    'sbom.cdx.json,' +
                    'rendered-kubernetes.yaml,' +
                    'test-results/**/*',
                allowEmptyArchive: true,
                fingerprint: true
            )

            cleanWs()
        }

        success {
            echo(
                "Deployed ${env.DOCKER_IMAGE_NAME}:" +
                "${env.IMAGE_TAG} from commit ${env.GIT_SHA}."
            )
        }
    }
}