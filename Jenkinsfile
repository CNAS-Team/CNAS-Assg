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

        stage('Scan Image') {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL --no-progress ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: KUBERNETES_CREDENTIALS_ID]) {
                    sh "kubectl apply -f k8s/ -n cnas"
                    sh "kubectl set image deployment/php-app php-app=${DOCKER_IMAGE_NAME}:${IMAGE_TAG} -n cnas"
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
        }
        success {
            echo "Pipeline completed successfully. Image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
