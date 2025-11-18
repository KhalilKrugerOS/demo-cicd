# Build and push Docker image to Docker Hub
# Usage: .\build-and-push.ps1 [-BuildNumber <number>] [-DockerUser <username>]

param(
    [string]$BuildNumber = "latest",
    [string]$DockerUser = "your-dockerhub-username",
    [string]$ImageName = "demo-cicd",
    [string]$ClusterName = "queueaicluster"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Building and Pushing Docker Image" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Image: $DockerUser/$ImageName:$BuildNumber"
Write-Host "==========================================" -ForegroundColor Cyan

# Build Docker image
Write-Host "✓ Building Docker image..." -ForegroundColor Green
docker build -t "$ImageName:$BuildNumber" .
docker tag "$ImageName:$BuildNumber" "$ImageName:latest"

# Tag for Docker Hub
Write-Host "✓ Tagging image for Docker Hub..." -ForegroundColor Green
docker tag "$ImageName:$BuildNumber" "$DockerUser/$ImageName:$BuildNumber"
docker tag "$ImageName:$BuildNumber" "$DockerUser/$ImageName:latest"

# Login to Docker Hub
Write-Host "✓ Logging in to Docker Hub..." -ForegroundColor Green
Write-Host "Please enter your Docker Hub credentials if prompted:" -ForegroundColor Yellow
docker login

# Push to Docker Hub
Write-Host "✓ Pushing images to Docker Hub..." -ForegroundColor Green
docker push "$DockerUser/$ImageName:$BuildNumber"
docker push "$DockerUser/$ImageName:latest"

# Load into Kind cluster
$clusters = kind get clusters 2>&1
if ($clusters -match $ClusterName) {
    Write-Host "✓ Loading images into Kind cluster: $ClusterName..." -ForegroundColor Green
    kind load docker-image "$ImageName:$BuildNumber" --name $ClusterName
    kind load docker-image "$ImageName:latest" --name $ClusterName
    Write-Host "✓ Images loaded into Kind cluster successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Kind cluster '$ClusterName' not found. Skipping image load." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  ✅ Build and Push Successful!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Images pushed to Docker Hub:"
Write-Host "  - $DockerUser/$ImageName:$BuildNumber"
Write-Host "  - $DockerUser/$ImageName:latest"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Deploy with: .\deploy.ps1 -BuildNumber $BuildNumber -DockerUser $DockerUser"
Write-Host "  2. Or use: helm upgrade --install demo-cicd ./helm --set image.tag=$BuildNumber"
Write-Host "==========================================" -ForegroundColor Cyan
