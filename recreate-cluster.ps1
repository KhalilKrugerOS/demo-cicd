# Recreate Kind cluster with proper port mapping for NodePort services
# This allows access to NodePort services via localhost:30080

param(
    [string]$ClusterName = "queueaicluster",
    [string]$ConfigFile = "kind-cluster-config.yaml"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Recreating Kind Cluster with Port Mapping" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cluster: $ClusterName"
Write-Host "Config: $ConfigFile"
Write-Host "==========================================" -ForegroundColor Cyan

# Warning prompt
Write-Host ""
Write-Host "⚠️  WARNING: This will delete the existing cluster!" -ForegroundColor Yellow
Write-Host "All deployments in the cluster will be lost." -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Continue? (y/n)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Aborted." -ForegroundColor Red
    exit 1
}

# Delete existing cluster
Write-Host ""
Write-Host "🗑️  Deleting existing cluster..." -ForegroundColor Yellow
kind delete cluster --name $ClusterName

# Create new cluster with config
Write-Host ""
Write-Host "🚀 Creating new cluster with port mapping..." -ForegroundColor Green
kind create cluster --config $ConfigFile

# Verify cluster
Write-Host ""
Write-Host "✓ Verifying cluster..." -ForegroundColor Green
kubectl cluster-info --context "kind-$ClusterName"

# Get nodes
Write-Host ""
Write-Host "✓ Cluster nodes:" -ForegroundColor Green
kubectl get nodes

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  ✅ Cluster Created Successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Cluster Name: $ClusterName"
Write-Host "Port Mappings:"
Write-Host "  - 30080 (NodePort) -> localhost:30080"
Write-Host "  - 30000 (NodePort) -> localhost:30000"
Write-Host "  - 30443 (NodePort) -> localhost:30443"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Deploy your application:"
Write-Host "     .\deploy.ps1 -BuildNumber latest -DockerUser khalilosx"
Write-Host ""
Write-Host "  2. Access at:"
Write-Host "     http://localhost:30080"
Write-Host "==========================================" -ForegroundColor Cyan
