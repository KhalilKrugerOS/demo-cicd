# Jenkins Pipeline Test Script
# Run this to verify Jenkins pipeline configuration and connectivity

param(
    [string]$JenkinsUrl = "http://localhost:8080",
    [string]$JobName = "demo-cicd-pipeline"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Jenkins Pipeline Configuration Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"
$allPassed = $true

# Test 1: Jenkins Accessibility
Write-Host "`n[Test 1] Checking Jenkins accessibility..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $JenkinsUrl -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Jenkins is accessible at $JenkinsUrl" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Cannot reach Jenkins at $JenkinsUrl" -ForegroundColor Red
    Write-Host "   Make sure Jenkins is running: docker ps | grep jenkins" -ForegroundColor Yellow
    $allPassed = $false
}

# Test 2: Docker Availability
Write-Host "`n[Test 2] Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if ($dockerVersion) {
        Write-Host "✅ Docker is running (version: $dockerVersion)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Docker is not available" -ForegroundColor Red
    $allPassed = $false
}

# Test 3: Kind Cluster
Write-Host "`n[Test 3] Checking Kind cluster..." -ForegroundColor Yellow
try {
    $clusters = kind get clusters 2>$null
    if ($clusters -match "queueaicluster") {
        Write-Host "✅ Kind cluster 'queueaicluster' exists" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Kind cluster 'queueaicluster' not found" -ForegroundColor Yellow
        Write-Host "   Available clusters: $clusters" -ForegroundColor Yellow
        $allPassed = $false
    }
} catch {
    Write-Host "❌ Kind is not installed or not in PATH" -ForegroundColor Red
    $allPassed = $false
}

# Test 4: kubectl
Write-Host "`n[Test 4] Checking kubectl..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    if ($kubectlVersion) {
        Write-Host "✅ kubectl is available" -ForegroundColor Green
        
        # Check context
        $currentContext = kubectl config current-context 2>$null
        Write-Host "   Current context: $currentContext" -ForegroundColor Cyan
        
        if ($currentContext -eq "kind-queueaicluster") {
            Write-Host "✅ kubectl is configured for queueaicluster" -ForegroundColor Green
        } else {
            Write-Host "⚠️  kubectl context is not set to kind-queueaicluster" -ForegroundColor Yellow
            Write-Host "   Run: kubectl config use-context kind-queueaicluster" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ kubectl is not installed or not in PATH" -ForegroundColor Red
    $allPassed = $false
}

# Test 5: Helm
Write-Host "`n[Test 5] Checking Helm..." -ForegroundColor Yellow
try {
    $helmVersion = helm version --short 2>$null
    if ($helmVersion) {
        Write-Host "✅ Helm is available ($helmVersion)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Helm is not installed or not in PATH" -ForegroundColor Red
    $allPassed = $false
}

# Test 6: Node.js and npm
Write-Host "`n[Test 6] Checking Node.js and npm..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    $npmVersion = npm --version 2>$null
    if ($nodeVersion -and $npmVersion) {
        Write-Host "✅ Node.js $nodeVersion and npm $npmVersion are available" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Node.js or npm not found" -ForegroundColor Red
    $allPassed = $false
}

# Test 7: Docker Hub Login Status
Write-Host "`n[Test 7] Checking Docker Hub authentication..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>$null | Select-String "Username"
    if ($dockerInfo) {
        Write-Host "✅ Docker is logged in" -ForegroundColor Green
        Write-Host "   $dockerInfo" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  Docker may not be logged in to Docker Hub" -ForegroundColor Yellow
        Write-Host "   Run: docker login" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check Docker login status" -ForegroundColor Yellow
}

# Test 8: Application Dependencies
Write-Host "`n[Test 8] Checking application dependencies..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    Write-Host "✅ package.json found" -ForegroundColor Green
    
    if (Test-Path "node_modules") {
        Write-Host "✅ node_modules exists (dependencies installed)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  node_modules not found" -ForegroundColor Yellow
        Write-Host "   Run: npm install" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ package.json not found" -ForegroundColor Red
}

# Test 9: Jenkinsfile
Write-Host "`n[Test 9] Checking Jenkinsfile..." -ForegroundColor Yellow
if (Test-Path "Jenkinsfile") {
    Write-Host "✅ Jenkinsfile exists" -ForegroundColor Green
    
    # Check for required stages
    $jenkinsContent = Get-Content "Jenkinsfile" -Raw
    $requiredStages = @("Checkout", "Build Docker Image", "Push to Docker Hub", "Deploy with Helm")
    
    foreach ($stage in $requiredStages) {
        if ($jenkinsContent -match $stage) {
            Write-Host "   ✓ Stage found: $stage" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Stage missing: $stage" -ForegroundColor Red
        }
    }
} else {
    Write-Host "❌ Jenkinsfile not found" -ForegroundColor Red
    $allPassed = $false
}

# Test 10: Helm Chart
Write-Host "`n[Test 10] Checking Helm chart..." -ForegroundColor Yellow
if (Test-Path "helm/Chart.yaml") {
    Write-Host "✅ Helm chart exists" -ForegroundColor Green
    
    # Validate chart
    try {
        $helmLint = helm lint ./helm 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Helm chart is valid" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Helm chart has issues:" -ForegroundColor Yellow
            Write-Host $helmLint -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Could not validate Helm chart" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Helm chart not found" -ForegroundColor Red
    $allPassed = $false
}

# Summary
Write-Host "`n==========================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "  ✅ All Tests Passed!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "`nYour environment is ready for Jenkins CI/CD pipeline!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Configure Jenkins credentials (see JENKINS_SETUP.md)"
    Write-Host "2. Create Jenkins pipeline job"
    Write-Host "3. Run first build"
    Write-Host "4. Monitor build in Jenkins UI: $JenkinsUrl"
} else {
    Write-Host "  ⚠️  Some Tests Failed" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "`nPlease fix the issues above before running the pipeline." -ForegroundColor Yellow
    Write-Host "Refer to JENKINS_SETUP.md for detailed setup instructions." -ForegroundColor Yellow
}

Write-Host "`nDetailed setup guide: JENKINS_SETUP.md" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
