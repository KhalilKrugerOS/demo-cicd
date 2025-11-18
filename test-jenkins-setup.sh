#!/bin/bash

# Jenkins Pipeline Test Script
# Run this to verify Jenkins pipeline configuration and connectivity

JENKINS_URL="${1:-http://localhost:8080}"
JOB_NAME="${2:-demo-cicd-pipeline}"

echo "=========================================="
echo "  Jenkins Pipeline Configuration Test"
echo "=========================================="

all_passed=true

# Test 1: Jenkins Accessibility
echo -e "\n[Test 1] Checking Jenkins accessibility..."
if curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL" | grep -q "200\|403"; then
    echo "✅ Jenkins is accessible at $JENKINS_URL"
else
    echo "❌ Cannot reach Jenkins at $JENKINS_URL"
    echo "   Make sure Jenkins is running: docker ps | grep jenkins"
    all_passed=false
fi

# Test 2: Docker Availability
echo -e "\n[Test 2] Checking Docker..."
if docker version > /dev/null 2>&1; then
    docker_version=$(docker version --format '{{.Server.Version}}')
    echo "✅ Docker is running (version: $docker_version)"
else
    echo "❌ Docker is not available"
    all_passed=false
fi

# Test 3: Kind Cluster
echo -e "\n[Test 3] Checking Kind cluster..."
if command -v kind > /dev/null 2>&1; then
    if kind get clusters 2>/dev/null | grep -q "queueaicluster"; then
        echo "✅ Kind cluster 'queueaicluster' exists"
    else
        echo "⚠️  Kind cluster 'queueaicluster' not found"
        echo "   Available clusters: $(kind get clusters 2>/dev/null)"
        all_passed=false
    fi
else
    echo "❌ Kind is not installed or not in PATH"
    all_passed=false
fi

# Test 4: kubectl
echo -e "\n[Test 4] Checking kubectl..."
if command -v kubectl > /dev/null 2>&1; then
    kubectl_version=$(kubectl version --client --short 2>/dev/null)
    echo "✅ kubectl is available"
    
    current_context=$(kubectl config current-context 2>/dev/null)
    echo "   Current context: $current_context"
    
    if [ "$current_context" = "kind-queueaicluster" ]; then
        echo "✅ kubectl is configured for queueaicluster"
    else
        echo "⚠️  kubectl context is not set to kind-queueaicluster"
        echo "   Run: kubectl config use-context kind-queueaicluster"
    fi
else
    echo "❌ kubectl is not installed or not in PATH"
    all_passed=false
fi

# Test 5: Helm
echo -e "\n[Test 5] Checking Helm..."
if command -v helm > /dev/null 2>&1; then
    helm_version=$(helm version --short 2>/dev/null)
    echo "✅ Helm is available ($helm_version)"
else
    echo "❌ Helm is not installed or not in PATH"
    all_passed=false
fi

# Test 6: Node.js and npm
echo -e "\n[Test 6] Checking Node.js and npm..."
if command -v node > /dev/null 2>&1 && command -v npm > /dev/null 2>&1; then
    node_version=$(node --version)
    npm_version=$(npm --version)
    echo "✅ Node.js $node_version and npm $npm_version are available"
else
    echo "❌ Node.js or npm not found"
    all_passed=false
fi

# Test 7: Docker Hub Login Status
echo -e "\n[Test 7] Checking Docker Hub authentication..."
if docker info 2>/dev/null | grep -q "Username"; then
    docker_username=$(docker info 2>/dev/null | grep "Username" | awk '{print $2}')
    echo "✅ Docker is logged in as: $docker_username"
else
    echo "⚠️  Docker may not be logged in to Docker Hub"
    echo "   Run: docker login"
fi

# Test 8: Application Dependencies
echo -e "\n[Test 8] Checking application dependencies..."
if [ -f "package.json" ]; then
    echo "✅ package.json found"
    
    if [ -d "node_modules" ]; then
        echo "✅ node_modules exists (dependencies installed)"
    else
        echo "⚠️  node_modules not found"
        echo "   Run: npm install"
    fi
else
    echo "❌ package.json not found"
fi

# Test 9: Jenkinsfile
echo -e "\n[Test 9] Checking Jenkinsfile..."
if [ -f "Jenkinsfile" ]; then
    echo "✅ Jenkinsfile exists"
    
    # Check for required stages
    required_stages=("Checkout" "Build Docker Image" "Push to Docker Hub" "Deploy with Helm")
    for stage in "${required_stages[@]}"; do
        if grep -q "$stage" Jenkinsfile; then
            echo "   ✓ Stage found: $stage"
        else
            echo "   ✗ Stage missing: $stage"
        fi
    done
else
    echo "❌ Jenkinsfile not found"
    all_passed=false
fi

# Test 10: Helm Chart
echo -e "\n[Test 10] Checking Helm chart..."
if [ -f "helm/Chart.yaml" ]; then
    echo "✅ Helm chart exists"
    
    # Validate chart
    if helm lint ./helm > /dev/null 2>&1; then
        echo "✅ Helm chart is valid"
    else
        echo "⚠️  Helm chart has issues:"
        helm lint ./helm
    fi
else
    echo "❌ Helm chart not found"
    all_passed=false
fi

# Summary
echo -e "\n=========================================="
if [ "$all_passed" = true ]; then
    echo "  ✅ All Tests Passed!"
    echo "=========================================="
    echo -e "\nYour environment is ready for Jenkins CI/CD pipeline!"
    echo -e "\nNext steps:"
    echo "1. Configure Jenkins credentials (see JENKINS_SETUP.md)"
    echo "2. Create Jenkins pipeline job"
    echo "3. Run first build"
    echo "4. Monitor build in Jenkins UI: $JENKINS_URL"
else
    echo "  ⚠️  Some Tests Failed"
    echo "=========================================="
    echo -e "\nPlease fix the issues above before running the pipeline."
    echo "Refer to JENKINS_SETUP.md for detailed setup instructions."
fi

echo -e "\nDetailed setup guide: JENKINS_SETUP.md"
echo "=========================================="
