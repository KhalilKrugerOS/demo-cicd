# Demo CI/CD Application

A complete CI/CD pipeline demonstration using Jenkins, Docker, Helm, and Kubernetes (Kind).

## 🚀 Features

- **Full CI/CD Pipeline**: Automated build, test, and deployment
- **Docker Integration**: Containerized application with multi-stage builds
- **Helm Charts**: Kubernetes deployment management
- **Kind Cluster**: Local Kubernetes testing with Kind (queueaicluster)
- **Docker Hub**: Automated image publishing
- **Quality Checks**: Linting, testing, and SonarQube analysis
- **Health Monitoring**: Built-in health checks and readiness probes

## 📦 What's Included

- Node.js Express application
- Complete Helm chart for Kubernetes deployment
- Jenkins pipeline configuration (Jenkinsfile)
- Deployment scripts (PowerShell and Bash)
- Docker configuration
- Kubernetes manifests
- SonarQube integration

## 🎯 Quick Start

### Prerequisites
- Docker Desktop installed and running
- Kind cluster running (named `queueaicluster`)
- kubectl configured
- Helm 3.x installed
- Docker Hub account

### Deploy in 3 Steps

1. **Build and Push to Docker Hub**
   ```powershell
   .\build-and-push.ps1 -BuildNumber 1 -DockerUser your-dockerhub-username
   ```

2. **Deploy to Kind Cluster**
   ```powershell
   .\deploy.ps1 -BuildNumber 1 -DockerUser your-dockerhub-username
   ```

3. **Access the Application**
   ```
   http://localhost:30080
   ```

📖 **Detailed Instructions**: See [QUICKSTART.md](QUICKSTART.md)

## 🏗️ Project Structure

```
demo-cicd/
├── helm/                       # Helm chart
│   ├── Chart.yaml             # Chart metadata
│   ├── values.yaml            # Default values
│   ├── values-custom.yaml     # Custom values template
│   └── templates/             # Kubernetes templates
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── hpa.yaml
│       └── ...
├── k8s/                       # Legacy K8s manifests
│   ├── deployment.yaml
│   └── service.yaml
├── test/                      # Test files
│   └── server.test.js
├── Dockerfile                 # Docker image definition
├── Jenkinsfile               # CI/CD pipeline
├── server.js                 # Application code
├── package.json              # Node.js dependencies
├── deploy.ps1                # PowerShell deployment script
├── deploy.sh                 # Bash deployment script
├── build-and-push.ps1        # PowerShell build script
├── build-and-push.sh         # Bash build script
├── QUICKSTART.md             # Quick start guide
└── HELM_DEPLOYMENT.md        # Detailed Helm documentation
```

## 🔄 CI/CD Pipeline

The Jenkins pipeline includes:

1. **Checkout** - Clone repository
2. **Install Dependencies** - npm install
3. **Lint** - Code quality checks
4. **Test** - Unit tests
5. **SonarQube Analysis** - Code quality analysis
6. **Build Docker Image** - Create container image
7. **Push to Docker Hub** - Publish image
8. **Load to Kind** - Load image to local cluster
9. **Deploy with Helm** - Deploy to Kubernetes
10. **Verify Deployment** - Health checks

## 🛠️ Available Commands

### Deployment
```powershell
# Deploy with default settings
.\deploy.ps1

# Deploy specific version
.\deploy.ps1 -BuildNumber 2 -DockerUser myusername

# Deploy with custom values
helm upgrade --install demo-cicd ./helm -f helm/values-custom.yaml
```

### Monitoring
```powershell
# Check deployment status
kubectl get all -l app.kubernetes.io/name=demo-cicd

# View logs
kubectl logs -l app.kubernetes.io/name=demo-cicd -f

# Check Helm release
helm list

# Get deployment details
kubectl describe deployment demo-cicd
```

### Cleanup
```powershell
# Uninstall Helm release
helm uninstall demo-cicd

# Remove Docker images
docker rmi demo-cicd:latest
```

## 🌐 API Endpoints

- `GET /` - Welcome message
- `GET /health` - Health check
- `GET /api/users` - Sample API endpoint

## 📚 Documentation

- [QUICKSTART.md](QUICKSTART.md) - Quick setup guide
- [HELM_DEPLOYMENT.md](HELM_DEPLOYMENT.md) - Comprehensive Helm documentation

## 🔧 Configuration

### Helm Values

Edit `helm/values.yaml` or create `helm/values-custom.yaml`:

```yaml
image:
  repository: your-dockerhub-username/demo-cicd
  tag: "1"

replicaCount: 2

service:
  type: NodePort
  nodePort: 30080

resources:
  limits:
    cpu: 200m
    memory: 256Mi
```

### Jenkins Credentials

Required Jenkins credentials:
- `dockerhub-credentials` - Docker Hub username/password
- `sonarqube-token` - SonarQube authentication token

## 🎓 Learning Resources

This project demonstrates:
- ✅ Jenkins CI/CD pipelines
- ✅ Docker containerization
- ✅ Helm chart creation
- ✅ Kubernetes deployments
- ✅ Kind local clusters
- ✅ Docker Hub integration
- ✅ GitOps workflows

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

ISC

## 👥 Authors

Google Club INSAT - DevOps Team

---

**Need Help?** Check the [HELM_DEPLOYMENT.md](HELM_DEPLOYMENT.md) for troubleshooting and advanced topics.