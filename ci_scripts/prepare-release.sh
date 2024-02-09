#!/bin/bash
# Simplifies the process of preparing a new helm chart release.
# Usage:
# ./prepare-release.sh
# Environment Variables:
# CREATE_BRANCH - If set to "false", changes remain local. Default is "true" to push changes.
# CHART_VERSION - Optionally overrides the chart version in Chart.yaml.
# APP_VERSION - Optionally overrides the app version in Chart.yaml.

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# Detect if CHART_VERSION is overridden via an environment variable.
CHART_VERSION_OVERRIDDEN=false
if [ -n "$CHART_VERSION" ]; then
    CHART_VERSION_OVERRIDDEN=true
fi
# Fetch chart and app versions, either from environment variables or Chart.yaml.
CHART_VERSION=${CHART_VERSION:-$(grep "^version:" "${CHART_FILE_PATH}" | awk '{print $2}')}
APP_VERSION=${APP_VERSION:-$(yq e ".appVersion" "${CHART_FILE_PATH}")}
# Defaults CREATE_BRANCH to true if not set.
CREATE_BRANCH=${CREATE_BRANCH:-true}

# Increment chart version if it matches the app version's major and minor.
chart_major=$(get_major_version "v$CHART_VERSION")
chart_minor=$(get_minor_version "v$CHART_VERSION")
app_major=$(get_major_version "v$APP_VERSION")
app_minor=$(get_minor_version "v$APP_VERSION")

# Conditional logic to increment chart version or align it based on app version.
if [[ "$CHART_VERSION_OVERRIDDEN" = true ]]; then
    echo "Using overridden chart version: $CHART_VERSION"
elif [[ "$chart_major" -eq "$app_major" && "$chart_minor" -eq "$app_minor" ]]; then
    chart_patch=$(get_patch_version "v$CHART_VERSION")
    CHART_VERSION="$chart_major.$chart_minor.$((chart_patch + 1))"
    echo "Incrementing chart version to $chart_version"
else
    CHART_VERSION="$app_major.$app_minor.0"
    echo "Aligning chart version to $chart_version due to major.minor mismatch with app version"
fi
echo "App version set to: $APP_VERSION"

# Function to update Chart.yaml with the new chart and app version.
function update_versions() {
    echo "Updating Chart.yaml with chart version: $1 and app version: $2"
    yq e ".version = \"$1\"" -i "${CHART_FILE_PATH}"
    yq e ".appVersion = \"$2\"" -i "${CHART_FILE_PATH}"
}

# Prepare the release by updating versions, creating a branch, and committing changes.
function prepare_release() {
    local version="$1" appVersion="$2" create_branch="$3"

    echo "Preparing release: $version"
    # Update Chart.yaml with the new versions.
    update_versions "$version" "$appVersion"

    # Generate new configs and update the changelog.
    make render
    make chlog-update

    # Stage any changes.
    git add .

    # Check if there are staged changes and if the create_branch flag is true.
    if git diff --staged --quiet; then
        echo "No changes to commit."
    else
        if [[ "$create_branch" == "true" ]]; then
            local branch_name="release-$version"
            echo "Creating branch: $branch_name"
            # Ensure the branch is correctly set up, either by creating or resetting it.
            setup_branch "$branch_name" "jvoravong/splunk-otel-collector-chart"
            # Commit and push only if create_branch is true.
            git commit -m "Prepare release $version"
            git push -u origin "$branch_name"
        else
            echo "Changes are staged but not committed or pushed because CREATE_BRANCH is not set to true."
            # Optionally, you might still want to commit locally even if not pushing.
            git commit -m "Prepare release $version"
        fi
    fi
}

prepare_release "$CHART_VERSION" "$APP_VERSION" "$CREATE_BRANCH"
