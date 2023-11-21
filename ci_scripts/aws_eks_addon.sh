#!/bin/bash

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# TODO: Add skopeo copy code for these images
# ---- Copy Collector Docker Image to ECR ----
# 709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-fluentd-hec:1.3.3
# ---- Copy Collector Docker Image to ECR ----
# 709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-ubi9:9.2-755.1697625012

# ---- Copy Collector Docker Image to ECR ----

# Set source and destination repository and tags
SRC_REPO="quay.io/signalfx/splunk-otel-collector"
SRC_TAG=$(grep "^appVersion:" $SCRIPT_DIR/../helm-charts/splunk-otel-collector/Chart.yaml | awk '{print $2}')
DST_REG="709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk"
DST_REPO="$DST_REG/splunk-otel-collector-app"
DST_TAG=$(grep "^version:" $SCRIPT_DIR/../helm-charts/splunk-otel-collector/Chart.yaml | awk '{print $2}')

if [ -z "$DST_TAG" ]; then
    echo "Destination tag (DST_TAG) is empty. Please check the Helm chart version."
    exit 1
fi

# Ensure Skopeo is installed
if ! command -v skopeo &> /dev/null; then
    echo "Skopeo could not be found. Please install it to continue."
    exit 1
fi

echo "Authenticating with Docker, Skopeo (Docker multi-arch power tool), and Helm with AWS ECR credentials..."
export AWS_PROFILE=marketplace

# Docker Login
if aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$DST_REPO"; then
    echo "Docker login successful."
else
    echo "Docker login failed."
    exit 1
fi

# Skopeo Login
if aws ecr get-login-password --region us-east-1 | skopeo login --username AWS --password-stdin "$DST_REPO"; then
    echo "Skopeo login successful."
else
    echo "Skopeo login failed."
    exit 1
fi

# Helm Registry Login
export HELM_EXPERIMENTAL_OCI=1
if aws ecr get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin "$DST_REG"; then
    echo "Helm registry login successful."
else
    echo "Helm registry login failed."
    exit 1
fi

# Check if the destination image already exists and compare digests
echo "Checking if the destination image already exists..."
if docker manifest inspect "$DST_REPO:$DST_TAG" &> /dev/null; then
  SRC_MANIFEST=$(docker manifest inspect "$SRC_REPO:$SRC_TAG")
  DST_MANIFEST=$(docker manifest inspect "$DST_REPO:$DST_TAG")

  SRC_DIGESTS=$(echo "$SRC_MANIFEST" | jq -r '.manifests[].digest')
  DST_DIGESTS=$(echo "$DST_MANIFEST" | jq -r '.manifests[].digest')

  # Sort and compare the digests
  SORTED_SRC_DIGESTS=$(echo "$SRC_DIGESTS" | sort)
  SORTED_DST_DIGESTS=$(echo "$DST_DIGESTS" | sort)

  if [ "$SORTED_SRC_DIGESTS" == "$SORTED_DST_DIGESTS" ]; then
      echo "The destination image already exists and has the same digests for all architectures. No need to copy."
  else
      echo "The destination image exists but has different digests. Aborting."
      exit 1
  fi
else
  echo "Destination image does not exist. Proceeding with the copy."
  # Copy the multi-architecture image from the source to the destination
  echo "Copying multi-architecture image from $SRC_REPO:$SRC_TAG to $DST_REPO:$DST_TAG..."
  skopeo copy --all "docker://$SRC_REPO:$SRC_TAG" "docker://$DST_REPO:$DST_TAG"

  if [ $? -ne 0 ]; then
      echo "Failed to copy the image."
      exit 1
  fi

  # Fetch the source and destination manifests
  SRC_MANIFEST=$(docker manifest inspect $SRC_REPO:$SRC_TAG)
  DST_MANIFEST=$(docker manifest inspect $DST_REPO:$DST_TAG)

  # Parse the manifests to get the digests for each architecture
  SRC_DIGESTS=$(echo "$SRC_MANIFEST" | jq -r '.manifests[].digest')
  DST_DIGESTS=$(echo "$DST_MANIFEST" | jq -r '.manifests[].digest')

  # Sort and compare the digests
  SORTED_SRC_DIGESTS=$(echo "$SRC_DIGESTS" | sort)
  SORTED_DST_DIGESTS=$(echo "$DST_DIGESTS" | sort)

  if [ "$SORTED_SRC_DIGESTS" == "$SORTED_DST_DIGESTS" ]; then
      echo "The source and destination manifests have identical content."
  else
      echo "The source and destination manifests do not have identical content."
      exit 1
  fi
fi

echo "Image copy completed successfully."

# ---- Package the Helm chart and upload to ECR ----
# Define VERSION for packaging Helm chart
VERSION=$(grep "^version:" "$SCRIPT_DIR/../helm-charts/splunk-otel-collector/Chart.yaml" | awk '{print $2}')
if [ -z "$VERSION" ]; then
    echo "Chart version (VERSION) is empty. Please check the Chart.yaml file."
    exit 1
fi

# Configure Helm for ECR
echo "Configuring Helm for ECR..."
export HELM_EXPERIMENTAL_OCI=1

# Package the Helm chart
helm package "$SCRIPT_DIR/../helm-charts/splunk-otel-collector" -d "$SCRIPT_DIR/../helm-charts/"

# Check for successful packaging
CHART_FILE="$SCRIPT_DIR/../helm-charts/splunk-otel-collector-$VERSION.tgz"
if [ ! -f "$CHART_FILE" ]; then
    echo "Failed to package Helm chart."
    exit 1
fi

# TODO: Add a check here to see if a the same helm chart docker image has already been uploaded, the naming conflict makes it tricky
# Push the packaged Helm chart to the repository
echo "Pushing the Helm chart $CHART_FILE to the repository oci://$DST_REG/splunk-otel-collector"
helm push "$CHART_FILE" "oci://$DST_REG"

# Check for successful push
if [ $? -ne 0 ]; then
    echo "Failed to push the Helm chart to the repository."
    exit 1
fi

# Optional: Clean up local images and chart packages after successful push
# rm "$CHART_FILE"

echo "All processes completed successfully."
