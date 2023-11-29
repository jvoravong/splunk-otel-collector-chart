#!/bin/bash

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# List of images to be processed
IMAGES=(
    "709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-otel-collector:0.86.66"
    "709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-otel-collector-app:0.86.66"
    "709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-fluentd-hec:1.3.3"
    "709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-ubi9:9.2-755.1697625012"
)

export AWS_PROFILE=marketplace

# Log in to ECR
echo "Logging in to AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 709825985650.dkr.ecr.us-east-1.amazonaws.com

# Process each image
for FULL_IMAGE_PATH in "${IMAGES[@]}"; do
    echo "Pulling image ${FULL_IMAGE_PATH}..."
    docker pull "$FULL_IMAGE_PATH"

    # Check if Minikube is running
    if minikube status &>/dev/null; then
        echo "Minikube is running. Loading image into Minikube: ${FULL_IMAGE_PATH}"
        minikube image load "$FULL_IMAGE_PATH"
        echo "Image loaded into Minikube successfully."
    else
        echo "Minikube is not running or not installed."
    fi

    # Check if Kind is running
    if kind get clusters &>/dev/null; then
        for cluster in $(kind get clusters); do
            echo "Loading image into Kind cluster: $cluster"
            kind load docker-image "$FULL_IMAGE_PATH" --name "$cluster"
            echo "Image loaded into Kind cluster $cluster successfully."
        done
    else
        echo "Kind is not running or not installed."
    fi
done

echo "All processes completed successfully."
