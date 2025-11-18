# Demo CI/CD - Helm Deployment Guide

This project includes a complete CI/CD pipeline using Jenkins, Docker Hub, Helm, and Kubernetes (Kind cluster).

## 📋 Prerequisites

- Docker installed and running
- Kind cluster running (named `queueaicluster`)
- kubectl configured
- Helm 3.x installed
- Docker Hub account
- Jenkins with required plugins

## 🚀 Quick Start

### 1. Manual Deployment (Local)

#### Windows (PowerShell)
```powershell
# Build and push to Docker Hub
.\build-and-push.ps1 -BuildNumber 1 -DockerUser your-dockerhub-username

# Deploy to Kind cluster
.\deploy.ps1 -BuildNumber 1 -DockerUser your-dockerhub-username
```

#### Linux/Mac (Bash)
```bash
# Make scripts executable
chmod +x build-and-push.sh deploy.sh

# Build and push to Docker Hub
./build-and-push.sh 1 your-dockerhub-username

# Deploy to Kind cluster
./deploy.sh 1 your-dockerhub-username
```

### 2. Jenkins CI/CD Pipeline

The Jenkinsfile includes a complete CI/CD pipeline with the following stages:

1. **Checkout** - Clone the repository
2. **Install Dependencies** - Install Node.js dependencies
3. **Lint** - Run ESLint
4. **Test** - Run unit tests with Mocha
5. **SonarQube Analysis** - Code quality analysis
6. **Build Docker Image** - Build the Docker image
7. **Push to Docker Hub** - Push image to Docker Hub
8. **Load Image to Kind Cluster** - Load image into Kind
9. **Deploy with Helm** - Deploy using Helm chart
10. **Verify Deployment** - Verify the deployment status

#### Jenkins Configuration Required

1. **Credentials needed in Jenkins:**
   - `sonarqube-token` - SonarQube authentication token
   - `dockerhub-credentials` - Docker Hub username/password

2. **Update the Jenkinsfile environment variables:**
   ```groovy
   KIND_CLUSTER_NAME = 'queueaicluster'  // Your Kind cluster name
   ```

3. **Jenkins plugins required:**
   - Docker Pipeline
   - Kubernetes CLI
   - SonarQube Scanner
   - Git

## 📦 Helm Chart Structure

```
helm/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── .helmignore            # Files to ignore
└── templates/
    ├── _helpers.tpl       # Template helpers
    ├── deployment.yaml    # Deployment manifest
    ├── service.yaml       # Service manifest
    ├── serviceaccount.yaml # Service account
    ├── hpa.yaml           # Horizontal Pod Autoscaler
    ├── ingress.yaml       # Ingress configuration
    └── NOTES.txt          # Post-install notes
```

## ⚙️ Helm Configuration

### Default Values (values.yaml)

- **Replicas:** 2
- **Image:** `your-dockerhub-username/demo-cicd:latest`
- **Service Type:** NodePort (port 30080)
- **Resources:**
  - Requests: 100m CPU, 128Mi Memory
  - Limits: 200m CPU, 256Mi Memory

### Customizing Deployment

```bash
# Deploy with custom values
helm upgrade --install demo-cicd ./helm \
  --set image.repository=your-dockerhub-username/demo-cicd \
  --set image.tag=1 \
  --set replicaCount=3

# Deploy with custom values file
helm upgrade --install demo-cicd ./helm -f custom-values.yaml
```

## 🔧 Useful Commands

### Helm Commands
```bash
# List releases
helm list -n default

# Get release status
helm status demo-cicd -n default

# Upgrade release
helm upgrade demo-cicd ./helm --set image.tag=2

# Rollback release
helm rollback demo-cicd 1

# Uninstall release
helm uninstall demo-cicd -n default

# Dry run (test without installing)
helm install demo-cicd ./helm --dry-run --debug
```

### Kubernetes Commands
```bash
# Get all resources
kubectl get all -l app.kubernetes.io/name=demo-cicd

# View logs
kubectl logs -l app.kubernetes.io/name=demo-cicd -f

# Describe deployment
kubectl describe deployment demo-cicd

# Get pods
kubectl get pods -l app.kubernetes.io/name=demo-cicd

# Port forward (alternative access)
kubectl port-forward svc/demo-cicd 8080:3000

# Scale deployment
kubectl scale deployment demo-cicd --replicas=3
```

### Docker Commands
```bash
# Build image locally
docker build -t demo-cicd:1 .

# Load image into Kind
kind load docker-image demo-cicd:1 --name queueaicluster

# List images in Kind cluster
docker exec -it queueaicluster-control-plane crictl images
```

## 🌐 Accessing the Application

After deployment, access the application:

- **Main endpoint:** http://localhost:30080
- **Health check:** http://localhost:30080/health
- **API endpoint:** http://localhost:30080/api/users

## 📊 Monitoring & Debugging

### View Application Logs
```bash
kubectl logs -l app.kubernetes.io/name=demo-cicd -f --tail=100
```

### Check Deployment Status
```bash
kubectl rollout status deployment/demo-cicd
kubectl rollout history deployment/demo-cicd
```

### Debug Pod Issues
```bash
# Describe pod
kubectl describe pod <pod-name>

# Get events
kubectl get events --sort-by=.metadata.creationTimestamp

# Execute commands in pod
kubectl exec -it <pod-name> -- sh
```

## 🔄 CI/CD Pipeline Flow

```
Code Push → GitHub
    ↓
Jenkins Webhook Trigger
    ↓
Checkout & Build
    ↓
Run Tests & Linting
    ↓
SonarQube Analysis
    ↓
Build Docker Image
    ↓
Push to Docker Hub
    ↓
Load Image to Kind Cluster
    ↓
Deploy with Helm
    ↓
Verify Deployment
    ↓
Success! 🎉
```

## 📝 Environment Variables

The application uses the following environment variables:

- `NODE_ENV` - Environment (production/development)
- `PORT` - Application port (default: 3000)

## 🔐 Security Best Practices

1. Store sensitive credentials in Jenkins Credentials Store
2. Use image pull secrets for private registries
3. Set resource limits to prevent resource exhaustion
4. Enable network policies in production
5. Regular security scanning with SonarQube

## 🐛 Troubleshooting

### Issue: Image pull errors
```bash
# Verify image exists in Kind
docker exec -it queueaicluster-control-plane crictl images | grep demo-cicd

# Reload image if needed
kind load docker-image demo-cicd:latest --name queueaicluster
```

### Issue: Pods not starting
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=demo-cicd

# View pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>
```

### Issue: Service not accessible
```bash
# Check service
kubectl get svc demo-cicd

# Verify NodePort
kubectl describe svc demo-cicd

# Check if Kind port mapping is correct
docker ps | grep queueaicluster
```

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

ISC License
