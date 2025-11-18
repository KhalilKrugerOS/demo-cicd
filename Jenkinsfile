pipeline {
    agent any

    environment {
        NODE_ENV = 'test'
        SONAR_HOST_URL = 'http://localhost:9000'
        SONAR_LOGIN = credentials('sonarqube-token')
        DOCKER_IMAGE_NAME = 'demo-cicd'
        KIND_CLUSTER_NAME = 'queueaicluster'
        HELM_RELEASE_NAME = 'demo-cicd'
        K8S_NAMESPACE = 'default'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies...'
                sh 'npm install'
            }
        }

        stage('Lint') {
            steps {
                echo 'Running linter...'
                sh 'npm run lint || true'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'npm test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh """
                        sonar-scanner \
                        -Dsonar.projectKey=demo-cicd \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_LOGIN}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    sh "docker build -t ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} ."
                    sh "docker tag ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        sh "docker tag ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} \$DOCKER_USER/${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker tag ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} \$DOCKER_USER/${DOCKER_IMAGE_NAME}:latest"
                        sh "docker push \$DOCKER_USER/${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker push \$DOCKER_USER/${DOCKER_IMAGE_NAME}:latest"
                        echo "Docker images pushed successfully!"
                        echo "  - \$DOCKER_USER/${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                        echo "  - \$DOCKER_USER/${DOCKER_IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Load Image to Kind Cluster') {
            steps {
                echo "Loading Docker image into Kind cluster: ${KIND_CLUSTER_NAME}..."
                script {
                    sh "kind load docker-image ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} --name ${KIND_CLUSTER_NAME}"
                    sh "kind load docker-image ${DOCKER_IMAGE_NAME}:latest --name ${KIND_CLUSTER_NAME}"
                    echo "Docker images loaded into Kind cluster successfully!"
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                echo "Deploying application with Helm to ${KIND_CLUSTER_NAME}..."
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            # Set kubectl context for Kind cluster
                            kubectl config use-context kind-${KIND_CLUSTER_NAME}
                            
                            # Update Helm dependencies
                            helm dependency update ./helm || true
                            
                            # Upgrade or install the Helm release
                            helm upgrade --install ${HELM_RELEASE_NAME} ./helm \
                                --namespace ${K8S_NAMESPACE} \
                                --create-namespace \
                                --set image.repository=\$DOCKER_USER/${DOCKER_IMAGE_NAME} \
                                --set image.tag=${env.BUILD_NUMBER} \
                                --set image.pullPolicy=IfNotPresent \
                                --wait \
                                --timeout 5m \
                                --atomic
                            
                            echo "Helm deployment completed!"
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment...'
                script {
                    sh """
                        # Wait for rollout to complete
                        kubectl rollout status deployment/${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE} --timeout=3m
                        
                        # Show deployment status
                        echo "\\n=== Deployment Status ==="
                        kubectl get deployment ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE}
                        
                        echo "\\n=== Pods ==="
                        kubectl get pods -l app.kubernetes.io/name=demo-cicd -n ${K8S_NAMESPACE}
                        
                        echo "\\n=== Services ==="
                        kubectl get service ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE}
                        
                        echo "\\n=== Application Info ==="
                        echo "Application deployed successfully!"
                        echo "Access the application at: http://localhost:30080"
                        echo "Health check: http://localhost:30080/health"
                        
                        echo "\\n=== Helm Release Info ==="
                        helm list -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline executed successfully!'
            echo "🚀 Application deployed to Kind cluster: ${KIND_CLUSTER_NAME}"
            echo "🌐 Access URL: http://localhost:30080"
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                sh """
                    echo "\\n=== Debug Information ==="
                    kubectl get all -n ${K8S_NAMESPACE} || true
                    kubectl describe deployment ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE} || true
                    kubectl logs -l app.kubernetes.io/name=demo-cicd -n ${K8S_NAMESPACE} --tail=50 || true
                """
            }
        }
        always {
            echo 'Cleaning up workspace...'
            sh 'docker logout || true'
        }
    }
}