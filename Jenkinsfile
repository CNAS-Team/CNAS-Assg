pipeline {
    agent any

    environment {
        DOCKER_REGISTRY_CREDENTIALS_ID = 'docker-hub-credentials'
        DOCKER_IMAGE_NAME = 'jqii/cnas-php-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBERNETES_CREDENTIALS_ID = 'kubeconfig-cluster-secret'
    }

    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Lint PHP Code') {
            steps {
                echo 'Checking PHP syntax...'
                sh 'php -l index.php || true'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image..."
                    appImage = docker.build("${DOCKER_IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', DOCKER_REGISTRY_CREDENTIALS_ID) {
                        echo "Pushing Docker image..."
                        appImage.push()
                        appImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    echo "Applying Kubernetes manifests..."
                    sh "kubectl apply -f k8s/"

                    echo "Updating PHP deployment image..."
                    sh "kubectl set image deployment/cnas-php-deployment cnas-php-container=${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"

                    echo "Checking rollout status..."
                    sh "kubectl rollout status deployment/cnas-php-deployment"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    sh "kubectl get pods"
                    sh "kubectl get svc"
                    sh "kubectl get deployment"
                }
            }
        }
    }

    post {
        success {
            echo "CI/CD pipeline completed successfully."
        }
        failure {
            echo "CI/CD pipeline failed. Check Jenkins logs."
        }
    }
}
