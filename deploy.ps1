# Deploy demo-cicd application using Helm to Kind cluster
# Usage: .\deploy.ps1 [-BuildNumber <number>] [-DockerUser <username>]

param(
    [string]$BuildNumber = "latest",
    [string]$DockerUser = "your-dockerhub-username",
    [string]$ClusterName = "queueaicluster",
    [string]$ReleaseName = "demo-cicd",
    [string]$Namespace = "default"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Deploying demo-cicd Application" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cluster: $ClusterName"
Write-Host "Release: $ReleaseName"
Write-Host "Namespace: $Namespace"
Write-Host "Image Tag: $BuildNumber"
Write-Host "Docker Hub User: $DockerUser"
Write-Host "==========================================" -ForegroundColor Cyan

# Check if Kind cluster exists
$clusters = kind get clusters 2>&1
if ($clusters -notmatch $ClusterName) {
    Write-Host "❌ Kind cluster '$ClusterName' not found!" -ForegroundColor Red
    Write-Host "Available clusters:"
    kind get clusters
    exit 1
}

# Set kubectl context
Write-Host "✓ Setting kubectl context..." -ForegroundColor Green
kubectl config use-context "kind-$ClusterName"

# Verify Helm is installed
if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Helm is not installed!" -ForegroundColor Red
    exit 1
}

$helmVersion = helm version --short
Write-Host "✓ Helm version: $helmVersion" -ForegroundColor Green

# Update Helm dependencies
Write-Host "✓ Updating Helm dependencies..." -ForegroundColor Green
helm dependency update ./helm 2>$null

# Deploy with Helm
Write-Host "✓ Deploying application with Helm..." -ForegroundColor Green
helm upgrade --install $ReleaseName ./helm `
    --namespace $Namespace `
    --create-namespace `
    --set image.repository=$DockerUser/demo-cicd `
    --set image.tag=$BuildNumber `
    --set image.pullPolicy=IfNotPresent `
    --wait `
    --timeout 5m

# Wait for deployment
Write-Host "✓ Waiting for deployment to be ready..." -ForegroundColor Green
kubectl rollout status deployment/$ReleaseName -n $Namespace --timeout=3m

# Show deployment info
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Deployment Status" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
kubectl get deployment $ReleaseName -n $Namespace
Write-Host ""
kubectl get pods -l app.kubernetes.io/name=demo-cicd -n $Namespace
Write-Host ""
kubectl get service $ReleaseName -n $Namespace

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  ✅ Deployment Successful!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "🌐 Application URL: http://localhost:30080" -ForegroundColor Yellow
Write-Host "💚 Health Check: http://localhost:30080/health" -ForegroundColor Yellow
Write-Host "📊 Helm Release: helm list -n $Namespace" -ForegroundColor Yellow
Write-Host ""
Write-Host "Useful commands:"
Write-Host "  - View logs: kubectl logs -l app.kubernetes.io/name=demo-cicd -n $Namespace -f"
Write-Host "  - Get pods: kubectl get pods -n $Namespace"
Write-Host "  - Describe deployment: kubectl describe deployment $ReleaseName -n $Namespace"
Write-Host "  - Uninstall: helm uninstall $ReleaseName -n $Namespace"
Write-Host "==========================================" -ForegroundColor Cyan
