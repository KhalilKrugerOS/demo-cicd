#!/bin/bash

# Recreate Kind cluster with proper port mapping for NodePort services
# This allows access to NodePort services via localhost:30080

set -e

CLUSTER_NAME="queueaicluster"
CONFIG_FILE="kind-cluster-config.yaml"

echo "=========================================="
echo "  Recreating Kind Cluster with Port Mapping"
echo "=========================================="
echo "Cluster: ${CLUSTER_NAME}"
echo "Config: ${CONFIG_FILE}"
echo "=========================================="

# Warning prompt
echo ""
echo "⚠️  WARNING: This will delete the existing cluster!"
echo "All deployments in the cluster will be lost."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Delete existing cluster
echo ""
echo "🗑️  Deleting existing cluster..."
kind delete cluster --name ${CLUSTER_NAME}

# Create new cluster with config
echo ""
echo "🚀 Creating new cluster with port mapping..."
kind create cluster --config ${CONFIG_FILE}

# Verify cluster
echo ""
echo "✓ Verifying cluster..."
kubectl cluster-info --context kind-${CLUSTER_NAME}

# Get nodes
echo ""
echo "✓ Cluster nodes:"
kubectl get nodes

echo ""
echo "=========================================="
echo "  ✅ Cluster Created Successfully!"
echo "=========================================="
echo "Cluster Name: ${CLUSTER_NAME}"
echo "Port Mappings:"
echo "  - 30080 (NodePort) -> localhost:30080"
echo "  - 30000 (NodePort) -> localhost:30000"
echo "  - 30443 (NodePort) -> localhost:30443"
echo ""
echo "Next steps:"
echo "  1. Deploy your application:"
echo "     ./deploy.sh latest khalilosx"
echo ""
echo "  2. Access at:"
echo "     http://localhost:30080"
echo "=========================================="
