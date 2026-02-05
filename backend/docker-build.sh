#!/bin/bash

# Docker Build Script
# Usage: ./docker-build.sh [dev|prod] [tag]
#
# Examples:
#   ./docker-build.sh dev                    # Build dev image with tag "latest"
#   ./docker-build.sh prod v1.0.0            # Build production image with tag "v1.0.0"

set -e

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
IMAGE_NAME="starttech-backend"

echo "=========================================="
echo "Docker Build Script"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "=========================================="

if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "production" ]; then
    echo "Building production image with Dockerfile.prod..."
    docker build \
        -f Dockerfile.prod \
        -t "$IMAGE_NAME:$IMAGE_TAG" \
        -t "$IMAGE_NAME:latest" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        .
    echo "✅ Production image built successfully!"
    echo "Image: $IMAGE_NAME:$IMAGE_TAG"
else
    echo "Building development image with Dockerfile..."
    docker build \
        -f Dockerfile \
        -t "$IMAGE_NAME:$IMAGE_TAG" \
        -t "$IMAGE_NAME:dev" \
        .
    echo "✅ Development image built successfully!"
    echo "Image: $IMAGE_NAME:$IMAGE_TAG"
fi

echo ""
echo "To run the image, use:"
if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "production" ]; then
    echo "  docker-compose -f docker-compose.prod.yml up -d"
else
    echo "  docker-compose -f docker-compose.yaml up -d"
fi
