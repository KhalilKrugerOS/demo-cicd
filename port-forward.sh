#!/bin/bash

# Port forward to access the application without NodePort requirements
# Usage: ./port-forward.sh [local-port]

NAMESPACE="default"
SERVICE_NAME="demo-cicd"
LOCAL_PORT=${1:-3000}
SERVICE_PORT=3000

echo "=========================================="
echo "  Setting up Port Forwarding"
echo "=========================================="
echo "Service: ${SERVICE_NAME}"
echo "Local Port: ${LOCAL_PORT}"
echo "Service Port: ${SERVICE_PORT}"
echo "=========================================="

# Check if service exists
if ! kubectl get svc ${SERVICE_NAME} -n ${NAMESPACE} &> /dev/null; then
    echo "❌ Service '${SERVICE_NAME}' not found in namespace '${NAMESPACE}'"
    echo ""
    echo "Available services:"
    kubectl get svc -n ${NAMESPACE}
    exit 1
fi

echo ""
echo "✓ Service found!"
echo "🌐 Access app at: http://localhost:${LOCAL_PORT}"
echo "💚 Health check: http://localhost:${LOCAL_PORT}/health"
echo "📋 API users: http://localhost:${LOCAL_PORT}/api/users"
echo ""
echo "Press Ctrl+C to stop port forwarding"
echo "=========================================="
echo ""

kubectl port-forward svc/${SERVICE_NAME} ${LOCAL_PORT}:${SERVICE_PORT} -n ${NAMESPACE}
