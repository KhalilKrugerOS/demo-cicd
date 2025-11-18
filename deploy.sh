#!/bin/bash

# Deploy demo-cicd application using Helm to Kind cluster
# Usage: ./deploy.sh [build-number] [dockerhub-username]

set -e

# Configuration
CLUSTER_NAME="queueaicluster"
RELEASE_NAME="demo-cicd"
NAMESPACE="default"
BUILD_NUMBER=${1:-"latest"}
DOCKER_USER=${2:-"khalilosx"}

echo "=========================================="
echo "  Deploying demo-cicd Application"
echo "=========================================="
echo "Cluster: ${CLUSTER_NAME}"
echo "Release: ${RELEASE_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Image Tag: ${BUILD_NUMBER}"
echo "Docker Hub User: ${DOCKER_USER}"
echo "=========================================="

# Check if Kind cluster exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Kind cluster '${CLUSTER_NAME}' not found!"
    echo "Available clusters:"
    kind get clusters
    exit 1
fi

# Set kubectl context
echo "✓ Setting kubectl context..."
kubectl config use-context "kind-${CLUSTER_NAME}"

# Verify Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed!"
    exit 1
fi

echo "✓ Helm version: $(helm version --short)"

# Update Helm dependencies
echo "✓ Updating Helm dependencies..."
helm dependency update ./helm || true

# Deploy with Helm
echo "✓ Deploying application with Helm..."
helm upgrade --install ${RELEASE_NAME} ./helm \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --set image.repository=${DOCKER_USER}/demo-cicd \
    --set image.tag=${BUILD_NUMBER} \
    --set image.pullPolicy=IfNotPresent \
    --wait \
    --timeout 5m

# Wait for deployment
echo "✓ Waiting for deployment to be ready..."
kubectl rollout status deployment/${RELEASE_NAME} -n ${NAMESPACE} --timeout=3m

# Show deployment info
echo ""
echo "=========================================="
echo "  Deployment Status"
echo "=========================================="
kubectl get deployment ${RELEASE_NAME} -n ${NAMESPACE}
echo ""
kubectl get pods -l app.kubernetes.io/name=demo-cicd -n ${NAMESPACE}
echo ""
kubectl get service ${RELEASE_NAME} -n ${NAMESPACE}

echo ""
echo "=========================================="
echo "  ✅ Deployment Successful!"
echo "=========================================="
echo "🌐 Application URL: http://localhost:30080"
echo "💚 Health Check: http://localhost:30080/health"
echo "📊 Helm Release: helm list -n ${NAMESPACE}"
echo ""
echo "Useful commands:"
echo "  - View logs: kubectl logs -l app.kubernetes.io/name=demo-cicd -n ${NAMESPACE} -f"
echo "  - Get pods: kubectl get pods -n ${NAMESPACE}"
echo "  - Describe deployment: kubectl describe deployment ${RELEASE_NAME} -n ${NAMESPACE}"
echo "  - Uninstall: helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}"
echo "=========================================="
