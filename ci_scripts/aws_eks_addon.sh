#!/bin/bash

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# ---- Copy Collector Docker Image to ECR ----

# Set source and destination repository and tags
SRC_REPO="quay.io/signalfx/splunk-otel-collector"
SRC_TAG="0.86.0"
DST_REPO="709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-otel-collector-app"
DST_TAG=$(grep "^version:" $SCRIPT_DIR/../helm-charts/splunk-otel-collector/Chart.yaml | awk '{print $2}')

if [ -z "$DST_TAG" ]; then
    echo "Destination tag (DST_TAG) is empty. Please check the Helm chart version."
    exit 1
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install it to continue."
    exit 1
fi

# Log in to the source repository if needed
# echo "Logging in to source repository..."
# docker login quay.io -u your-username -p your-password

# Log in to the destination repository if needed
# echo "Logging in to destination repository..."
# aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $DST_REPO

# Initialize the array for the manifests
MANIFESTS=()

# Pull, tag, and push images for all architectures
echo "Starting to process architectures..."
for digest in $(docker manifest inspect $SRC_REPO:$SRC_TAG | jq -r '.manifests[].digest'); do
    ARCH_IMAGE="$SRC_REPO@$digest"
    NEW_TAG="$DST_REPO:$DST_TAG-$(echo $digest | cut -d ":" -f2)"
    IMAGE_ID=$(docker inspect --format='{{.Id}}' $ARCH_IMAGE)

    echo "Processing image with ID $IMAGE_ID..."
    docker pull $ARCH_IMAGE
    if [ $? -ne 0 ]; then
        echo "Failed to pull image $ARCH_IMAGE"
        exit 1
    fi

    docker tag $ARCH_IMAGE $NEW_TAG
    if [ $? -ne 0 ]; then
        echo "Failed to tag image $ARCH_IMAGE as $NEW_TAG"
        exit 1
    fi

    echo "Pushing image $NEW_TAG..."
    docker push $NEW_TAG
    if [ $? -ne 0 ]; then
        echo "Failed to push image $NEW_TAG"
        exit 1
    fi

    # Validate that the pushed image is good and has a size greater than 0
    PUSHED_IMAGE_SIZE=$(docker inspect --format='{{.Size}}' $NEW_TAG)
    if [ $? -ne 0 ] || [ "$PUSHED_IMAGE_SIZE" -le 0 ]; then
        echo "Validation failed for image $NEW_TAG. Image is either invalid or has size 0."
        exit 1
    fi

    echo "Image $NEW_TAG with ID $IMAGE_ID and size $PUSHED_IMAGE_SIZE pushed successfully."

    MANIFESTS+=($NEW_TAG)
done

echo "Manifests created for the following images:"
printf '%s\n' "${MANIFESTS[@]}"

# Create and push the manifest list
echo "Creating manifest list for $DST_REPO:$DST_TAG..."
docker manifest create $DST_REPO:$DST_TAG "${MANIFESTS[@]}"
if [ $? -ne 0 ]; then
    echo "Failed to create the manifest list."
    exit 1
fi

echo "Pushing manifest list..."
docker manifest push $DST_REPO:$DST_TAG
if [ $? -ne 0 ]; then
    echo "Failed to push the manifest list."
    exit 1
fi
docker manifest inspect $DST_REPO:$DST_TAG

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

# ---- Package the Helm chart and upload to ECR ----
# Define VERSION for packaging Helm chart
VERSION=$(grep "^version:" "$SCRIPT_DIR/../helm-charts/splunk-otel-collector/Chart.yaml" | awk '{print $2}')
if [ -z "$VERSION" ]; then
    echo "Chart version (VERSION) is empty. Please check the Chart.yaml file."
    exit 1
fi

# Package the Helm chart
helm package "$SCRIPT_DIR/../helm-charts/splunk-otel-collector" -d "$SCRIPT_DIR/../helm-charts/"

# Check for successful packaging
CHART_FILE="$SCRIPT_DIR/../helm-charts/splunk-otel-collector-$VERSION.tgz"
if [ ! -f "$CHART_FILE" ]; then
    echo "Failed to package Helm chart."
    exit 1
fi

# Push the packaged Helm chart to the repository
echo "Pushing the Helm chart $CHART_FILE to the repository..."
helm push "$CHART_FILE" oci://709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk

# Check for successful push
if [ $? -ne 0 ]; then
    echo "Failed to push the Helm chart to the repository."
    exit 1
fi
docker manifest inspect 709825985650.dkr.ecr.us-east-1.amazonaws.com/splunk/splunk-otel-collector:$VERSION

# Verify the pushed Helm chart Docker image size
HELM_IMAGE="$DST_REPO/splunk-otel-collector:$VERSION"
HELM_IMAGE_SIZE=$(docker inspect --format='{{.Size}}' $HELM_IMAGE)
if [ $? -ne 0 ] || [ "$HELM_IMAGE_SIZE" -le 0 ]; then
    echo "Validation failed for Helm chart image $HELM_IMAGE. Image is either invalid or has size 0."
    exit 1
fi

echo "Helm chart $CHART_FILE with size $HELM_IMAGE_SIZE uploaded successfully."

# Optional: Clean up local images and chart packages after successful push
# docker rmi $SRC_REPO:$SRC_TAG $DST_REPO:$DST_TAG
# rm "$CHART_FILE"

echo "All processes completed successfully."
