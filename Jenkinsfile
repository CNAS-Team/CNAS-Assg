pipeline {
    agent any

    environment {
        DOCKER_REGISTRY_CREDENTIALS_ID = 'docker-hub-credentials'
        DOCKER_IMAGE_NAME = 'sinoceratops/cnas-php-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBERNETES_CREDENTIALS_ID = 'kubeconfig-cluster-secret'
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Ensure latest repo state is pulled cleanly
                checkout scm
            }
        }

        stage('Static Security Scan') {
            steps {
                echo "=== Scanning Source Code & Manifests for Misconfigurations ==="
                // Scans workspace for exposed secrets or vulnerable IaC configurations
                sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL .'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    appImage = docker.build("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Scan Image') {
            steps {
                echo "=== Scanning Container Image with Trivy ==="
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL --no-progress ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', DOCKER_REGISTRY_CREDENTIALS_ID) {
                        echo "=== Pushing Container Image to Registry ==="
                        appImage.push()
                        appImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    // Reset local git changes so 'latest' string always exists
                    echo "=== Resetting Local Git Changes ==="
                    sh "git checkout -- k8s/06-php-deployment.yaml || true"

                    // Apply Kyverno policies first and wait for the webhook to be ready
                    echo "=== Applying Kyverno Admission Policies ==="
                    sh "kubectl apply -f k8s/kyverno/"
                    sh "kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=90s || true"

                    echo "=== Deploying Workloads to 'cnas' Namespace ==="
                    // Inject the exact build tag into the manifest before applying
                    sh "sed -i 's|sinoceratops/cnas-php-app:latest|${DOCKER_IMAGE_NAME}:${IMAGE_TAG}|g' k8s/06-php-deployment.yaml"
                    // Apply all remaining k8s manifests (NetworkPolicies, RBAC, Services, Secrets)
                    sh "kubectl apply -f k8s/ -n cnas"
                    sh "kubectl rollout status deployment/php-app -n cnas"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    sh "kubectl get pods,svc,deployment -n cnas"
                }
            }
        }
    }

    post {
        always {
            // Clean workspace post-build to prevent lingering artifacts or secret leaks
            cleanWs()
        }
        failure {
            echo "Pipeline failed — check the logs above for details. Triggering automated rollback..."
            withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                sh "kubectl rollout undo deployment/php-app -n cnas || true"
                echo "Rollback triggered for php-app deployment."
            }
        }
        success {
            echo "Pipeline completed successfully. Image deployed: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
