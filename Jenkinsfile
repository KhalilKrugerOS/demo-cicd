pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS'  // Make sure this matches your NodeJS installation name in Jenkins
    }
    
    environment {
        NODE_ENV = 'test'
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
                sh 'npm run lint || true'  // || true to not fail the build
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'npm test'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'echo "No build step required for Node.js"'
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                script {
                    // Stop existing process if running
                    sh '''
                        if pgrep -f "node server.js" > /dev/null; then
                            pkill -f "node server.js"
                            echo "Stopped existing process"
                        fi
                    '''
                    
                    // Start the application in background
                    sh 'nohup npm start > /dev/null 2>&1 &'
                    echo 'Application deployed successfully!'
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
            // You can add notifications here (email, Slack, etc.)
        }
        failure {
            echo 'Pipeline failed!'
            // You can add failure notifications here
        }
        always {
            echo 'Cleaning up...'
            cleanWs()  // Clean workspace after build
        }
    }
}