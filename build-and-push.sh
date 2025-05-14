#!/bin/bash
# Script to build and push InnovativeHypeChat Docker images

# Set your Docker Hub username
DOCKER_USERNAME="micahppls"
# Set your application name
APP_NAME="innovative-hype-chat"
# Set version
VERSION="1.0.0"

# Login to Docker Hub
echo "Logging in to Docker Hub..."
docker login

# Build the main application image (contains both backend API and client build)
echo "Building main application image..."
docker build -t $DOCKER_USERNAME/$APP_NAME:$VERSION -t $DOCKER_USERNAME/$APP_NAME:latest -f Dockerfile.custom .

# Push the main application image
echo "Pushing main application image..."
docker push $DOCKER_USERNAME/$APP_NAME:$VERSION
docker push $DOCKER_USERNAME/$APP_NAME:latest

# Build the optional frontend-only image (nginx)
# echo "Building frontend-only image..."
# docker build -f Dockerfile.custom --target nginx-client -t $DOCKER_USERNAME/$APP_NAME-client:$VERSION -t $DOCKER_USERNAME/$APP_NAME-client:latest .

# echo "Pushing frontend-only image..."
# docker push $DOCKER_USERNAME/$APP_NAME-client:$VERSION
# docker push $DOCKER_USERNAME/$APP_NAME-client:latest

# If you want to build the RAG API image too, uncomment these lines
# echo "Building RAG API image..."
# docker build -t $DOCKER_USERNAME/$APP_NAME-rag-api:$VERSION -t $DOCKER_USERNAME/$APP_NAME-rag-api:latest -f Dockerfile.rag-api .
# 
# echo "Pushing RAG API image..."
# docker push $DOCKER_USERNAME/$APP_NAME-rag-api:$VERSION
# docker push $DOCKER_USERNAME/$APP_NAME-rag-api:latest

echo "Build and push completed!" 