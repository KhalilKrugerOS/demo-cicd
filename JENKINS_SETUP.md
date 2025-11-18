# Jenkins CI/CD Pipeline Setup Guide

## Prerequisites
- ✅ Jenkins is running
- ✅ Required plugins installed:
  - Docker Pipeline
  - Kubernetes CLI Plugin
  - Git Plugin
  - Pipeline Plugin
  - Credentials Plugin
  - SonarQube Scanner (optional)

## Step 1: Add Credentials in Jenkins

### 1.1 Docker Hub Credentials
1. Go to Jenkins Dashboard → **Manage Jenkins** → **Credentials**
2. Click **(global)** → **Add Credentials**
3. Configure:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: `khalilosx` (your Docker Hub username)
   - **Password**: [Your Docker Hub password or access token]
   - **ID**: `dockerhub-credentials`
   - **Description**: Docker Hub credentials for khalilosx
4. Click **Create**

### 1.2 SonarQube Token (Optional)
1. Generate token in SonarQube:
   - Login to SonarQube → **My Account** → **Security** → **Generate Token**
   - Name: `jenkins-demo-cicd`
   - Copy the token

2. Add to Jenkins:
   - Go to **Manage Jenkins** → **Credentials** → **Add Credentials**
   - **Kind**: Secret text
   - **Scope**: Global
   - **Secret**: [Paste your SonarQube token]
   - **ID**: `sonarqube-token`
   - **Description**: SonarQube authentication token
   - Click **Create**

### 1.3 Kubeconfig for Kind Cluster (Optional but Recommended)
1. Get your kubeconfig:
   ```powershell
   # Copy kubeconfig content
   Get-Content $env:USERPROFILE\.kube\config | clip
   ```

2. Add to Jenkins:
   - **Kind**: Secret file
   - **Scope**: Global
   - **File**: Upload or paste kubeconfig
   - **ID**: `kubeconfig-queueaicluster`
   - **Description**: Kubeconfig for queueaicluster
   - Click **Create**

## Step 2: Configure Jenkins System Settings

### 2.1 Docker Configuration
1. Go to **Manage Jenkins** → **System Configuration** → **Configure System**
2. Scroll to **Docker** section
3. Verify Docker is available on Jenkins agent/controller

### 2.2 SonarQube Server (Optional)
1. **Manage Jenkins** → **Configure System**
2. Scroll to **SonarQube servers**
3. Click **Add SonarQube**
   - **Name**: `SonarQube`
   - **Server URL**: `http://localhost:9000` (adjust if different)
   - **Server authentication token**: Select `sonarqube-token`
4. Click **Save**

### 2.3 Install Required Tools on Jenkins Agent
Ensure these tools are available on the Jenkins agent:
- Node.js (v18+)
- npm
- Docker
- kubectl
- Helm
- kind

## Step 3: Create Jenkins Pipeline Job

### 3.1 Create New Pipeline
1. Jenkins Dashboard → **New Item**
2. **Item name**: `demo-cicd-pipeline`
3. Select **Pipeline**
4. Click **OK**

### 3.2 Configure Pipeline

#### General Settings
- **Description**: CI/CD Pipeline for Queue AI Demo Application
- ☑ **Discard old builds**
  - Days to keep: 30
  - Max builds: 20

#### Build Triggers
Choose one:
- ☑ **Poll SCM**: `H/5 * * * *` (every 5 minutes)
- ☑ **GitHub hook trigger** (if webhook configured)

#### Pipeline Definition
1. **Definition**: Pipeline script from SCM
2. **SCM**: Git
3. **Repository URL**: `https://github.com/KhalilKrugerOS/demo-cicd.git`
4. **Credentials**: (Add GitHub credentials if private repo)
5. **Branch Specifier**: `*/main`
6. **Script Path**: `Jenkinsfile`

#### Or use Pipeline Script directly:
- **Definition**: Pipeline script
- Copy the Jenkinsfile content

### 3.3 Save Configuration
Click **Save**

## Step 4: Test the Pipeline

### 4.1 Manual Test Build
1. Go to pipeline job: `demo-cicd-pipeline`
2. Click **Build Now**
3. Watch the build progress in **Console Output**

### 4.2 Expected Pipeline Stages
```
✓ Checkout
✓ Install Dependencies
✓ Lint
✓ Test
✓ SonarQube Analysis (optional)
✓ Build Docker Image
✓ Push to Docker Hub
✓ Load Image to Kind Cluster
✓ Deploy with Helm
✓ Verify Deployment
```

## Step 5: Verify Each Stage

### 5.1 Check Docker Hub
```powershell
# Verify image was pushed
docker pull khalilosx/demo-cicd:latest
```

Or visit: https://hub.docker.com/r/khalilosx/demo-cicd/tags

### 5.2 Check Kubernetes Deployment
```powershell
# Check pods
kubectl get pods -l app.kubernetes.io/name=demo-cicd

# Check service
kubectl get svc demo-cicd

# Check Helm release
helm list
```

### 5.3 Test Application
```powershell
# Port forward
kubectl port-forward svc/demo-cicd 3000:3000

# Test endpoints
curl http://localhost:3000
curl http://localhost:3000/health
curl http://localhost:3000/api/users
```

## Step 6: Troubleshooting

### Common Issues and Solutions

#### Issue 1: Docker Login Failed
```groovy
# Verify credentials ID matches in Jenkinsfile
withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', ...)])
```

#### Issue 2: kubectl Not Found
Install kubectl on Jenkins agent:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Issue 3: Helm Not Found
Install Helm on Jenkins agent:
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### Issue 4: Kind Cluster Access
Jenkins agent must have access to Kind cluster:
```bash
# Copy kubeconfig to Jenkins agent
kind get kubeconfig --name queueaicluster > /var/jenkins_home/.kube/config
```

#### Issue 5: Node.js/npm Not Found
Install Node.js on Jenkins agent:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Step 7: Advanced Configuration

### 7.1 Parameterized Build
Add build parameters:
1. In job configuration → **This project is parameterized**
2. Add parameters:
   - **String Parameter**:
     - Name: `BUILD_TAG`
     - Default: `latest`
     - Description: Docker image tag
   - **Choice Parameter**:
     - Name: `DEPLOY_ENV`
     - Choices: `dev`, `staging`, `production`
     - Description: Target environment

### 7.2 Email Notifications
1. **Manage Jenkins** → **Configure System** → **Extended E-mail Notification**
2. Configure SMTP settings
3. Add post-build action in Jenkinsfile:
```groovy
post {
    failure {
        emailext (
            subject: "Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: "Check console output at ${env.BUILD_URL}",
            to: "team@example.com"
        )
    }
}
```

### 7.3 Slack Notifications
1. Install Slack Notification Plugin
2. Configure Slack workspace and channel
3. Add to Jenkinsfile:
```groovy
post {
    success {
        slackSend channel: '#deployments',
                  color: 'good',
                  message: "Deployed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
}
```

## Step 8: Pipeline Testing Checklist

### Pre-Deployment Tests
- ☑ Credentials configured correctly
- ☑ Docker Hub accessible
- ☑ Kind cluster running (`kind get clusters`)
- ☑ kubectl context set (`kubectl config current-context`)
- ☑ Helm installed and working (`helm version`)

### During Pipeline Execution
- ☑ Code checkout successful
- ☑ Dependencies installed without errors
- ☑ Tests pass (100% success rate expected)
- ☑ Docker image builds successfully
- ☑ Image pushed to Docker Hub
- ☑ Image loaded into Kind cluster
- ☑ Helm deployment succeeds
- ☑ Pods reach Running state
- ☑ Health checks pass

### Post-Deployment Verification
```powershell
# 1. Check pipeline status
# Jenkins UI → Build History → Console Output

# 2. Verify Docker Hub
# https://hub.docker.com/r/khalilosx/demo-cicd

# 3. Check Kubernetes
kubectl get all -l app.kubernetes.io/name=demo-cicd

# 4. Test application
kubectl port-forward svc/demo-cicd 3000:3000
curl http://localhost:3000/health

# 5. Check logs
kubectl logs -l app.kubernetes.io/name=demo-cicd --tail=50
```

## Step 9: Continuous Integration Workflow

### Automated Triggers
1. **Push to main branch** → Triggers pipeline
2. **Pull request** → Run tests only (optional separate pipeline)
3. **Tag creation** → Build release version

### GitOps Workflow
```
Developer Push → GitHub → Jenkins Webhook → Pipeline Runs →
Docker Build → Push to Hub → Deploy to K8s → Health Check
```

## Quick Test Script

Run this to verify everything works:
```powershell
# 1. Trigger Jenkins build
# (Use Jenkins UI or REST API)

# 2. Wait for build to complete (check Jenkins)

# 3. Verify deployment
kubectl get pods -l app.kubernetes.io/name=demo-cicd
kubectl get svc demo-cicd
helm list

# 4. Test application
kubectl port-forward svc/demo-cicd 3000:3000 &
Start-Sleep -Seconds 5
Invoke-WebRequest http://localhost:3000 -UseBasicParsing
Invoke-WebRequest http://localhost:3000/health -UseBasicParsing

# 5. Check Docker Hub
docker pull khalilosx/demo-cicd:latest
docker images | Select-String "khalilosx/demo-cicd"
```

## Resources

- Jenkins Dashboard: http://localhost:8080
- Docker Hub: https://hub.docker.com/r/khalilosx/demo-cicd
- SonarQube: http://localhost:9000 (if running)
- Application: http://localhost:3000 (via port-forward)

## Success Indicators

✅ Jenkins build: SUCCESS (green)
✅ Docker Hub: New image with build number tag
✅ Kubernetes: Pods running (2/2 Ready)
✅ Application: Responding to HTTP requests
✅ Helm: Release deployed successfully

---

**Next Steps:**
1. Set up GitHub webhook for automatic builds
2. Add integration tests
3. Configure monitoring and alerting
4. Set up production environment
