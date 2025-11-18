# Port forward to access the application without NodePort requirements
# Usage: .\port-forward.ps1 [-LocalPort 3000]

param(
    [int]$LocalPort = 3000,
    [string]$ServiceName = "demo-cicd",
    [string]$Namespace = "default",
    [int]$ServicePort = 3000
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Setting up Port Forwarding" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Service: $ServiceName"
Write-Host "Local Port: $LocalPort"
Write-Host "Service Port: $ServicePort"
Write-Host "==========================================" -ForegroundColor Cyan

# Check if service exists
try {
    kubectl get svc $ServiceName -n $Namespace | Out-Null
    Write-Host ""
    Write-Host "✓ Service found!" -ForegroundColor Green
} catch {
    Write-Host "❌ Service '$ServiceName' not found in namespace '$Namespace'" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available services:"
    kubectl get svc -n $Namespace
    exit 1
}

Write-Host "🌐 Access app at: http://localhost:$LocalPort" -ForegroundColor Yellow
Write-Host "💚 Health check: http://localhost:$LocalPort/health" -ForegroundColor Yellow
Write-Host "📋 API users: http://localhost:$LocalPort/api/users" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop port forwarding" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

kubectl port-forward svc/$ServiceName ${LocalPort}:${ServicePort} -n $Namespace
