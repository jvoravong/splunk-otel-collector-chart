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

# Functions
update_versions() {
    yq e ".version = \"$LATEST_CHART_VERSION\"" -i "${CHART_FILE_PATH}"
    yq e ".appVersion = \"$LATEST_APP_VERSION\"" -i "${CHART_FILE_PATH}"
}

notify_workflows_for_need_update() {
    emit_output "NEED_UPDATE"
    emit_output "LATEST_CHART_VERSION"
    emit_output "LATEST_APP_VERSION"
}

prepare_release() {
    echo "Preparing release: $LATEST_CHART_VERSION with app version: $LATEST_APP_VERSION"
    update_versions
    make render && make chlog-update
    git add .

    if ! git diff --staged --quiet; then
        NEED_UPDATE=1
        notify_workflows_for_need_update

        BRANCH_NAME="release-update"
        if [[ "$CREATE_BRANCH" == "true" ]]; then
            BRANCH_NAME="release-$LATEST_CHART_VERSION"
            setup_branch "$BRANCH_NAME" "$OWNER/splunk-otel-collector-chart"
            git commit -m "Prepare release $LATEST_CHART_VERSION"
            git push -u origin "$branch_name"
        else
            echo "Staging changes without pushing. CREATE_BRANCH is not set to true."
#            git commit -m "Prepare release $LATEST_CHART_VERSION"
        fi
        emit_output "BRANCH_NAME"
        echo "Created branch: $BRANCH_NAME"
    else
        echo "No changes to commit."
    fi
}

CHART_VERSION_OVERRIDDEN=${CHART_VERSION:+true}
APP_VERSION_OVERRIDDEN=${APP_VERSION:+true}

# Fetch or set default versions
CHART_VERSION=${CHART_VERSION:-$(yq e ".version" "${CHART_FILE_PATH}")}
APP_VERSION=${APP_VERSION:-$(yq e ".appVersion" "${CHART_FILE_PATH}")}
CREATE_BRANCH=${CREATE_BRANCH:-true}
chart_major=$(get_major_version "v$CHART_VERSION")
chart_minor=$(get_minor_version "v$CHART_VERSION")
app_major=$(get_major_version "v$APP_VERSION")
app_minor=$(get_minor_version "v$APP_VERSION")

# Conditional logic to increment the collector version
LATEST_APP_VERSION=$(curl -L -qs -H 'Accept: application/vnd.github+json' https://api.github.com/repos/"$OWNER"/splunk-otel-collector/releases/latest | jq -r .tag_name | sed 's/^v//')
if [[ "$APP_VERSION_OVERRIDDEN" = true ]]; then
    debug "Using overridden APP version: $APP_VERSION"
    LATEST_APP_VERSION=$APP_VERSION
fi

# Conditional logic to increment chart version or align it based on app version.
LATEST_CHART_VERSION=CURRENT_CHART_VERSION
if [[ "$CHART_VERSION_OVERRIDDEN" == "true" ]]; then
    if helm search repo your-repo/splunk-otel-collector --versions | grep -q "splunk-otel-collector-$CHART_VERSION"; then
        echo "Version $CHART_VERSION already exists. Exiting."
        exit 1
    fi
elif [[ "$chart_major" -eq "$app_major" && "$chart_minor" -eq "$app_minor" ]]; then
    chart_patch=$(get_patch_version "v$CHART_VERSION")
    LATEST_CHART_VERSION="$chart_major.$chart_minor.$((chart_patch + 1))"
    debug "Incrementing chart version to $LATEST_CHART_VERSION"
else
    LATEST_CHART_VERSION="$app_major.$app_minor.0"
    debug "Aligning chart version to $LATEST_CHART_VERSION due to major.minor mismatch with app version"
fi

setup_git
prepare_release
