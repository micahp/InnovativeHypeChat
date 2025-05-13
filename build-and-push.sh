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

# Build the main API image
echo "Building main API image..."
docker build -t $DOCKER_USERNAME/$APP_NAME:$VERSION -t $DOCKER_USERNAME/$APP_NAME:latest -f Dockerfile.custom --target api-build .

# Push the main API image
echo "Pushing main API image..."
docker push $DOCKER_USERNAME/$APP_NAME:$VERSION
docker push $DOCKER_USERNAME/$APP_NAME:latest

# If you want to build the RAG API image too, uncomment these lines
# echo "Building RAG API image..."
# docker build -t $DOCKER_USERNAME/$APP_NAME-rag-api:$VERSION -t $DOCKER_USERNAME/$APP_NAME-rag-api:latest -f Dockerfile.rag-api .
# 
# echo "Pushing RAG API image..."
# docker push $DOCKER_USERNAME/$APP_NAME-rag-api:$VERSION
# docker push $DOCKER_USERNAME/$APP_NAME-rag-api:latest

echo "Build and push completed!" 