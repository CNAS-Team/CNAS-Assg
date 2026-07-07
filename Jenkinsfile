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
                    sh "kubectl apply -f k8s/"
                    sh "kubectl set image deployment/cnas-php-deployment cnas-php-container=${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
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
}
