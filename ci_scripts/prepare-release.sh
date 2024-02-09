#!/bin/bash
# Purpose: Prepares a new release of the helm chart by updating the version, creating a feature branch, and pushing changes.
# Usage: ./prepare-release.sh (No VERSION parameter needed)

# Include the base utility functions for setting and debugging variables, and version handling
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# Automatically lookup the chart version
chart_file_path="${CHART_FILE_PATH}"
chart_version=$(grep "^version:" "$chart_file_path" | awk '{print $2}')

# Extract appVersion from Chart.yaml
app_version=$(yq e ".appVersion" "$chart_file_path")

# Prefix variables with chart_ or app_ for clarity
chart_provided_major=$(get_major_version "v$chart_version")
chart_provided_minor=$(get_minor_version "v$chart_version")
app_major=$(get_major_version "v$app_version")
app_minor=$(get_minor_version "v$app_version")

# Validate and increment version if necessary
if [[ "$chart_provided_major" -eq "$app_major" && "$chart_provided_minor" -eq "$app_minor" ]]; then
    echo "Chart version matches appVersion's major and minor: $chart_version"
    # Extract patch version, increment by one
    chart_patch=$(get_patch_version "v$chart_version")
    chart_new_patch=$((chart_patch + 1))
    chart_version="$chart_provided_major.$chart_provided_minor.$chart_new_patch"
    echo "Incremented chart version to: $chart_version"
else
    echo "Chart version does not match appVersion's major.minor. Aligning and setting version to: $app_major.$app_minor.0"
    chart_version="$app_major.$app_minor.0"
fi

function update_chart_version() {
    local version=$1
    echo "Updating Chart.yaml with version: $version"
    yq e ".version = \"$version\"" -i "$chart_file_path"
}

function prepare_release() {
    local version="$1"

    # Setup branch
    local branch="release-$version"
    echo "Setting up branch: $branch"
    setup_branch "$branch" "jvoravong/splunk-otel-collector-chart"

    # Update Chart version
    update_chart_version "$version"

    # Run make commands
    make render
    make chlog-update

    # Commit and push changes
    git add .
    if git diff --staged --quiet; then
        echo "No changes to commit, exiting gracefully."
        exit 0
    else
        git commit -m "prepare release-$version"
        git push -u origin "$branch"
    fi
}

echo "Preparing release with version: $chart_version"
prepare_release "$chart_version"
