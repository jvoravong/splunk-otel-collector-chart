#!/bin/bash

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# ---- Copy Collector Docker Image from ECR to Minikube ----

# Set source repository and tags
SRC_REPO="709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-otel-collector-app"
SRC_TAG=$(grep "^version:" "$SCRIPT_DIR/../helm-charts/splunk-otel-collector/Chart.yaml" | awk '{print $2}')
export AWS_PROFILE=marketplace

# Full image path with tag
FULL_IMAGE_PATH="${SRC_REPO}:${SRC_TAG}"

# Log in to ECR
echo "Logging in to AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$SRC_REPO"

# Pull the image
echo "Pulling image ${FULL_IMAGE_PATH}..."
docker pull "$FULL_IMAGE_PATH"

echo "All processes completed successfully."
