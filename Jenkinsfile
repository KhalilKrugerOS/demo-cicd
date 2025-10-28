pipeline {
    agent any

    environment {
        NODE_ENV = 'test'
        SONAR_HOST_URL = 'http://localhost:9000'    // URL de ton conteneur SonarQube
        SONAR_LOGIN = credentials('sonarqube-token') // ID du token configuré dans Jenkins
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
                sh 'npm run lint || true'  // Ne fait pas échouer le build si le lint échoue
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
                    sh 'docker build -t demo-cicd:latest .'
                    sh "docker tag demo-cicd:latest demo-cicd:${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        sh "docker tag demo-cicd:latest \$DOCKER_USER/demo-cicd:latest"
                        sh "docker tag demo-cicd:latest \$DOCKER_USER/demo-cicd:${env.BUILD_NUMBER}"
                        sh "docker push \$DOCKER_USER/demo-cicd:latest"
                        sh "docker push \$DOCKER_USER/demo-cicd:${env.BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Load Image to kind') {
            steps {
                echo 'Loading Docker image into kind cluster...'
                script {
                    sh 'kind load docker-image demo-cicd:latest --name kind'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes (kind)...'
                script {
                    sh '''
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        
                        # Wait for rollout to complete
                        kubectl rollout status deployment/demo-cicd --timeout=2m
                        
                        # Show deployment status
                        kubectl get pods -l app=demo-cicd
                        kubectl get service demo-cicd-service
                        
                        echo "Application deployed to Kubernetes!"
                        echo "Access the app at: http://localhost:30080"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            echo 'Cleaning up...'
            cleanWs()
        }
    }
}
