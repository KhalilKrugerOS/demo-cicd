# Quick Setup Guide

## 🎯 Prerequisites Check

Run these commands to verify your setup:

```powershell
# Check Docker
docker --version

# Check Kind cluster
kind get clusters

# Check kubectl
kubectl cluster-info --context kind-queueaicluster

# Check Helm
helm version
```

## 🚀 Quick Start (3 Steps)

### Step 1: Update Configuration

Edit `helm/values.yaml` and replace `your-dockerhub-username` with your actual Docker Hub username:

```yaml
image:
  repository: YOUR-DOCKERHUB-USERNAME/demo-cicd
```

### Step 2: Build and Push (Windows)

```powershell
# Replace with your Docker Hub username
.\build-and-push.ps1 -BuildNumber 1 -DockerUser YOUR-DOCKERHUB-USERNAME
```

### Step 3: Deploy to Kind Cluster

```powershell
# Replace with your Docker Hub username
.\deploy.ps1 -BuildNumber 1 -DockerUser YOUR-DOCKERHUB-USERNAME
```

### Access Your Application

```powershell
# Open in browser
Start-Process "http://localhost:30080"

# Or use curl
curl http://localhost:30080
curl http://localhost:30080/health
```

## 🔧 Jenkins Setup

### 1. Add Jenkins Credentials

Go to Jenkins → Manage Jenkins → Credentials → Add Credentials

**Docker Hub Credentials:**
- Kind: Username with password
- ID: `dockerhub-credentials`
- Username: Your Docker Hub username
- Password: Your Docker Hub password/token

**SonarQube Token:**
- Kind: Secret text
- ID: `sonarqube-token`
- Secret: Your SonarQube token

### 2. Configure Jenkins Job

1. Create a new Pipeline job
2. Configure GitHub repository
3. Set Pipeline script from SCM
4. Point to your Jenkinsfile
5. Save and build

### 3. Verify Pipeline

The pipeline will automatically:
- ✅ Build and test the application
- ✅ Run SonarQube analysis
- ✅ Build Docker image
- ✅ Push to Docker Hub
- ✅ Load image to Kind cluster
- ✅ Deploy with Helm
- ✅ Verify deployment

## 📊 Verify Deployment

```powershell
# Check Helm release
helm list

# Check pods
kubectl get pods -l app.kubernetes.io/name=demo-cicd

# Check service
kubectl get svc demo-cicd

# View logs
kubectl logs -l app.kubernetes.io/name=demo-cicd -f

# Test the application
Invoke-WebRequest -Uri http://localhost:30080 -UseBasicParsing
```

## 🎉 Success Indicators

You should see:
- ✅ Helm release status: `deployed`
- ✅ Pods status: `Running`
- ✅ Service type: `NodePort` on port 30080
- ✅ Application responding at http://localhost:30080

## 🔄 Update Application

```powershell
# Build new version
.\build-and-push.ps1 -BuildNumber 2 -DockerUser YOUR-DOCKERHUB-USERNAME

# Deploy new version
.\deploy.ps1 -BuildNumber 2 -DockerUser YOUR-DOCKERHUB-USERNAME
```

## 🧹 Cleanup

```powershell
# Uninstall Helm release
helm uninstall demo-cicd

# Remove Docker images (optional)
docker rmi demo-cicd:latest
docker rmi YOUR-DOCKERHUB-USERNAME/demo-cicd:latest
```

## 📚 Next Steps

- Read [HELM_DEPLOYMENT.md](HELM_DEPLOYMENT.md) for detailed documentation
- Configure Jenkins webhooks for automatic deployments
- Set up monitoring and alerting
- Configure ingress for production use

## ❓ Need Help?

- Check logs: `kubectl logs -l app.kubernetes.io/name=demo-cicd`
- Check events: `kubectl get events --sort-by=.metadata.creationTimestamp`
- Describe deployment: `kubectl describe deployment demo-cicd`
