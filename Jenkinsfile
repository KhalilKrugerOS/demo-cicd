pipeline {
    agent any

    environment {
        NODE_ENV = 'test'
        DOCKER_IMAGE_NAME = 'demo-cicd'
        KIND_CLUSTER_NAME = 'queueaicluster'
        HELM_RELEASE_NAME = 'demo-cicd'
        K8S_NAMESPACE = 'default'
        KUBECONFIG = '/var/jenkins_home/.kube/config'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }

        stage('Verify Environment') {
            steps {
                echo 'Verifying environment and cluster access...'
                sh '''
                    echo "=== Tool Versions ==="
                    node --version
                    npm --version
                    docker --version
                    kubectl version --client
                    helm version --short
                    
                    echo "\\n=== Kubectl Configuration ==="
                    export KUBECONFIG=/var/jenkins_home/.kube/config
                    cat $KUBECONFIG | grep server:
                    
                    echo "\\n=== Cluster Connection ==="
                    kubectl cluster-info
                    kubectl get nodes
                '''
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
                        sh '''
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker tag ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} $DOCKER_USER/${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}
                            docker tag ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} $DOCKER_USER/${DOCKER_IMAGE_NAME}:latest
                            docker push $DOCKER_USER/${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}
                            docker push $DOCKER_USER/${DOCKER_IMAGE_NAME}:latest
                            echo "✓ Images pushed: $DOCKER_USER/${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}, latest"
                        '''
                    }
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                echo "Deploying application with Helm to ${KIND_CLUSTER_NAME}..."
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            export KUBECONFIG=/var/jenkins_home/.kube/config
                            
                            # Verify cluster connection
                            kubectl config use-context kind-${KIND_CLUSTER_NAME}
                            kubectl cluster-info
                            
                            # Deploy with Helm
                            helm upgrade --install ${HELM_RELEASE_NAME} ./helm \
                                --namespace ${K8S_NAMESPACE} \
                                --create-namespace \
                                --set image.repository=\$DOCKER_USER/${DOCKER_IMAGE_NAME} \
                                --set image.tag=${env.BUILD_NUMBER} \
                                --set image.pullPolicy=Always \
                                --wait \
                                --timeout 5m \
                                --atomic
                            
                            echo "✓ Helm deployment completed!"
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
                        export KUBECONFIG=/var/jenkins_home/.kube/config
                        
                        kubectl rollout status deployment/${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE} --timeout=3m
                        
                        echo "\\n=== Deployment Status ==="
                        kubectl get deployment ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE}
                        
                        echo "\\n=== Pods ==="
                        kubectl get pods -l app.kubernetes.io/name=demo-cicd -n ${K8S_NAMESPACE}
                        
                        echo "\\n=== Services ==="
                        kubectl get service ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE}
                        
                        echo "\\n✅ Application deployed successfully!"
                        echo "🌐 Access: http://localhost:30080"
                        echo "💚 Health: http://localhost:30080/health"
                        
                        helm list -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline executed successfully!'
            echo "🚀 Application: ${KIND_CLUSTER_NAME}"
            echo "🌐 URL: http://localhost:30080"
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                sh """
                    export KUBECONFIG=/var/jenkins_home/.kube/config
                    echo "\\n=== Debug Information ==="
                    kubectl get all -n ${K8S_NAMESPACE} 2>&1 || echo "Could not get resources"
                    kubectl describe deployment ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE} 2>&1 || echo "No deployment"
                    kubectl logs -l app.kubernetes.io/name=demo-cicd -n ${K8S_NAMESPACE} --tail=50 2>&1 || echo "No logs"
                """
            }
        }
        always {
            sh 'docker logout || true'
        }
    }
}