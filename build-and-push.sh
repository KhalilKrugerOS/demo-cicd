#!/bin/bash

# Build and push Docker image to Docker Hub
# Usage: ./build-and-push.sh [build-number] [dockerhub-username]

set -e

# Configuration
BUILD_NUMBER=${1:-"latest"}
DOCKER_USER=${2:-"khalilosx"}
IMAGE_NAME="demo-cicd"
CLUSTER_NAME="queueaicluster"

echo "=========================================="
echo "  Building and Pushing Docker Image"
echo "=========================================="
echo "Image: ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}"
echo "=========================================="

# Build Docker image
echo "✓ Building Docker image..."
docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest

# Tag for Docker Hub
echo "✓ Tagging image for Docker Hub..."
docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_USER}/${IMAGE_NAME}:latest

# Login to Docker Hub (if not already logged in)
echo "✓ Logging in to Docker Hub..."
echo "Please enter your Docker Hub credentials if prompted:"
docker login

# Push to Docker Hub
echo "✓ Pushing images to Docker Hub..."
docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
docker push ${DOCKER_USER}/${IMAGE_NAME}:latest

# Load into Kind cluster
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "✓ Loading images into Kind cluster: ${CLUSTER_NAME}..."
    kind load docker-image ${IMAGE_NAME}:${BUILD_NUMBER} --name ${CLUSTER_NAME}
    kind load docker-image ${IMAGE_NAME}:latest --name ${CLUSTER_NAME}
    echo "✓ Images loaded into Kind cluster successfully!"
else
    echo "⚠️  Kind cluster '${CLUSTER_NAME}' not found. Skipping image load."
fi

echo ""
echo "=========================================="
echo "  ✅ Build and Push Successful!"
echo "=========================================="
echo "Images pushed to Docker Hub:"
echo "  - ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}"
echo "  - ${DOCKER_USER}/${IMAGE_NAME}:latest"
echo ""
echo "Next steps:"
echo "  1. Deploy with: ./deploy.sh ${BUILD_NUMBER} ${DOCKER_USER}"
echo "  2. Or use: helm upgrade --install demo-cicd ./helm --set image.tag=${BUILD_NUMBER}"
echo "=========================================="
