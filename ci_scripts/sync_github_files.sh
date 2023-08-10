#!/bin/bash

# Function to download a file from GitHub
# Arguments:
# $1: URL of the file
# $2: Destination directory
download_from_github() {
    local repo_url="$1"
    local dest_dir="$2"

    # Convert the provided URL to a raw GitHub URL for downloading
    local raw_url="${repo_url/github.com/raw.githubusercontent.com}"
    raw_url="${raw_url/blob\///}"

    # Extract the filename from the URL
    local file_name=$(basename "$repo_url")

    # Create the destination directory if it doesn't exist
    mkdir -p "$dest_dir"

    # Download the file
    curl -s "$raw_url" > "${dest_dir}/${file_name}"

    # Add the comment at the top
    echo "# This file is managed automatically. Sourced from: $repo_url" | cat - "${dest_dir}/${file_name}" > temp && mv temp "${dest_dir}/${file_name}"

    # Make the file executable
    chmod +x "${dest_dir}/${file_name}"
}

# For now, we'll handle the provided example URLs.
# In a real-world situation, this script could be further parameterized to handle multiple URLs and destination directories.
download_from_github "https://github.com/open-telemetry/opentelemetry-operator/blob/main/hack/install-kuttl.sh" "${1:-.hack}"
download_from_github "https://github.com/open-telemetry/opentelemetry-operator/blob/main/hack/install-metrics-server.sh" "${1:-.hack}"

# For the wildcard case, we need to list the files from the repo and then download each.
# This is a bit more involved since GitHub doesn't provide a direct way to list files with a wildcard.
# Ideally, you'd use the GitHub API for this, but for simplicity, I'm demonstrating a naive approach here.
urls=$(curl -s "https://github.com/open-telemetry/opentelemetry-operator/tree/main/" | grep 'kind-.*\.yaml' | sed 's/.*href="\([^"]*\)".*/\1/' | sed 's/^/https:\/\/github.com/')

for url in $urls; do
    download_from_github "$url" "${2:-./test}"
done
