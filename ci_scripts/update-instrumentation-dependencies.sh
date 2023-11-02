#!/bin/bash
# Purpose: Updates Splunk images for auto-instrumentation.
# Notes:
#   - This script updates the instrumentation in values.yaml, including operator, network explorer, and log collection images.
#   - This script will always pull the latest version of a specific instrumentation image.
#   - OpenTelemetry Operator images are updated differently and are not handled by this script.
# Example Usage:
#   ./update-images-operator-splunk.sh generate_github_workflow_matrix
#   ./update-images-operator-splunk.sh update_image nodejs {TODO OTHER ARGS}

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_FILE_PATH="$SCRIPT_DIR/../helm-charts/splunk-otel-collector/values.yaml"
source "$SCRIPT_DIR/base_util.sh"

# Function to get the latest tag from a Docker registry, quay.io, or ghcr.io
get_latest_tag() {
    local repo_value="$1"

    # For quay.io
    if [[ "$repo_value" =~ ^quay\.io/([^/]+)(/([^/]+))?$ ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo_name="${BASH_REMATCH[3]}"
        local latest_api="https://quay.io/api/v1/repository/$owner/$repo_name/tag/?limit=1&onlyActiveTags=true"
        echo $(curl -sL "$latest_api" | jq -r '.tags[0].name')

    # For ghcr.io
    elif [[ "$repo_value" =~ ^ghcr\.io/([^/]+)/([^/]+)/([^/]+)$ ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo_name="${BASH_REMATCH[2]}"
        local latest_api="https://api.github.com/repos/${owner}/${repo_name}/tags"
        echo $(curl -sL -qs -H 'Accept: application/vnd.github+json' "$latest_api" | jq -r '.[0].name')

    # Default for Docker Hub
    else
        local latest_api="https://registry.hub.docker.com/v2/repositories/$repo_value/tags/?page_size=2"  # Fetch only the two latest tags
        echo $(curl -sL "$latest_api" | jq -r '.results[] | select(.name != "latest") | .name')
    fi
}

# Function to update image tags in values.yaml
generate_github_workflow_matrix() {
    # Find the line number of the first non-comment line in values.yaml
    setd "YAML_FILE_START_OFFSET" "$(grep -nE '^[^#]' "$VALUES_FILE_PATH" | head -1 | cut -d: -f1)"

    # Get paths in values.yaml leading to a 'repository'
    setd "repository_paths" "$(yq e '.. | select(has("repository") and has("tag")) | path | join(".")' "$VALUES_FILE_PATH")"

    # Initialize matrix variable
    matrix="matrix: { include: ["

    IFS=$'\n'
    for path in $repository_paths; do
        setd "repository_value" "$(yq e ".$path.repository" "$VALUES_FILE_PATH")"
        setd "current_tag" "$(yq e ".$path.tag" "$VALUES_FILE_PATH")"

        # Skip if the current_tag is empty or "latest"
        if [[ -z "$current_tag" || "$current_tag" == "latest" ]]; then
            continue
        # The operator subchart must be in lockstep with images prefixed with autoinstrumentation-*
        # Skip if repository_value starts with "autoinstrumentation-"
        elif [[ "$repository_value" =~ autoinstrumentation- ]]; then
            continue
        fi

        # Check if the current tag matches the latest version
        # The network explorer is a special case for how to update the involved images
        if [[ "$path" =~ networkExplorer ]]; then
            latest_tag=$(get_latest_tag "${repository_value}/splunk-network-explorer-kernel-collector")
        else
            latest_tag=$(get_latest_tag "$repository_value")
        fi

        if [[ "$current_tag" != "$latest_tag" ]]; then
            # Extract line number using yq for the tag query
            tag_line=$(( $(yq -e ".$path.tag | line" "$VALUES_FILE_PATH") + YAML_FILE_START_OFFSET ))
            matrix+="\n  { path: \"$path\", repository: \"$repository_value\", current_tag: \"$current_tag\", latest_tag: \"$latest_tag\", tag_line: \"$tag_line\" },"
        fi
    done

    matrix+="] }"

    # Echo the matrix variable for further use
    echo -e "$matrix"  # Use -e option to interpret escape sequences like \n
}

update_image() {
    # ---- Validate Input Arguments ----
    # Check for command-line arguments
    if [ "$#" -eq 0 ]; then
        echo "Error: No arguments provided."
        echo "Usage: $0 <instrumentation-library-name> [--debug]"
        exit 1
    fi

    # ---- Initialize Variables ----
    # Set the instrumentation library name
    setd "INST_LIB_NAME" "$1"

    # Set repository-related variables
    setd "REPO" "ghcr.io/${OWNER}/splunk-otel-${INST_LIB_NAME}/splunk-otel-${INST_LIB_NAME}"
    setd "REPOSITORY_LOCAL_PATH" "operator.instrumentation.spec.${INST_LIB_NAME}.repository"
    setd "REPOSITORY_LOCAL" "$(yq eval ".${REPOSITORY_LOCAL_PATH}" "${VALUES_FILE_PATH}")"
    setd "TAG_LOCAL_PATH" "operator.instrumentation.spec.${INST_LIB_NAME}.tag"
    setd "TAG_LOCAL" "$(yq eval ".${TAG_LOCAL_PATH}" "${VALUES_FILE_PATH}")"

    # ---- Fetch Latest Version ----
    # Fetch the latest version from GitHub
    setd "LATEST_API" "https://api.github.com/repos/${OWNER}/splunk-otel-${INST_LIB_NAME}/releases/latest"
    setd "LATEST_API_CURL" "curl -L -qs -H 'Accept: application/vnd.github+json' \"$LATEST_API\" | jq -r .tag_name"
    setd "TAG_UPSTREAM" "$(eval $LATEST_API_CURL)"

    # ---- Display Version Information ----
    # Display current and latest versions
    echo "${REPOSITORY_LOCAL} -> Local tag: ${TAG_LOCAL}, Latest tag: $TAG_UPSTREAM"

    # ---- Update Version Information ----
    # If needed, update the tag version in values.yaml
    setd "NEED_UPDATE" "${NEED_UPDATE:-0}"  # Sets NEED_UPDATE to its current value or 0 if not set
    if [ "$TAG_UPSTREAM" == "$TAG_LOCAL" ]; then
        echo "We are already up to date. Nothing else to do."
    elif [[ -z "$TAG_LOCAL" || "$TAG_LOCAL" == "null" || "$TAG_LOCAL" != "$TAG_UPSTREAM" ]]; then
        debug "Upserting value for ${REPOSITORY_LOCAL}:${TAG_LOCAL}"
        yq eval -i ".${TAG_LOCAL_PATH} = \"$TAG_UPSTREAM\"" "${VALUES_FILE_PATH}"
        setd "NEED_UPDATE" 1  # Setting NEED_UPDATE to 1 if update is needed
    fi

    # Emit the NEED_UPDATE variable for GitHub output or stdout
    emit_output "NEED_UPDATE"

    echo "Image update process completed successfully!"
    exit 0
}

# Check if the script is run as a standalone script or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If run as a standalone script, execute the main function based on the first argument
    case "$1" in
    "generate_github_workflow_matrix")
        generate_github_workflow_matrix "$2"  # Pass values.yaml path as an argument
        ;;
    "update_image")
        update_image "$2" "$3"  # Pass instrumentation-library-name and other arguments as needed
        ;;
    *)
        echo "Invalid usage. Use 'generate_github_workflow_matrix' or 'update_image' as the first argument."
        exit 1
        ;;
    esac
fi
