pipeline {
    agent any

    environment {
        DOCKER_REGISTRY_CREDENTIALS_ID = 'docker-hub-credentials'
        DOCKER_IMAGE_NAME = 'jqii/cnas-php-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBERNETES_CREDENTIALS_ID = 'kubeconfig-cluster-secret'
    }

    stages {
        stage('List Files') {
            steps {
                sh 'ls -la'
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
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL --no-progress ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', DOCKER_REGISTRY_CREDENTIALS_ID) {
                        appImage.push()
                        appImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    // Apply Kyverno policies first and wait for the webhook to be ready
                    sh "kubectl apply -f k8s/kyverno/"
                    sh "kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=90s || true"
                    // Inject the exact build tag into the manifest before applying
                    sh "sed -i 's|jqii/cnas-php-app:latest|${DOCKER_IMAGE_NAME}:${IMAGE_TAG}|g' k8s/06-php-deployment.yaml"
                    sh "kubectl apply -f k8s/ -n cnas"
                    sh "kubectl rollout status deployment/php-app -n cnas"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    sh "kubectl get pods -n cnas"
                    sh "kubectl get svc -n cnas"
                    sh "kubectl get deployment -n cnas"
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed — check the logs above for details."
            withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                sh "kubectl rollout undo deployment/php-app -n cnas || true"
                echo "Rollback triggered for php-app deployment."
            }
        }
        success {
            echo "Pipeline completed successfully. Image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
