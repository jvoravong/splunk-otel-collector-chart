#!/bin/bash
# Purpose: Updates Splunk images for auto-instrumentation.
# Notes:
#   - This script updates the instrumentation libraries from Splunk's repositories.
#   - This script will always pull the latest version of a specific Splunk instrumentation library.
#   - OpenTelemetry images are updated differently and are not handled by this script.
# Parameters:
#   1: Name of the instrumentation library (mandatory)
#   --debug: Enable debug mode (optional)
#
# Example Usage:
#   ./update-images-operator-splunk.sh java
#   ./update-images-operator-splunk.sh nodejs --debug=

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

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
      # Trim 'docker.io/' from the start of repo_value if it exists
      repo_value="${repo_value#docker.io/}"
      local tags_api="https://registry.hub.docker.com/v2/repositories/$repo_value/tags/?page_size=100"  # Fetch a list of tags, increase page_size if needed
      # Get the digest of the 'latest' tag if it exists
      local latest_digest=$(curl -sL "$tags_api" | jq -r '.results[] | select(.name == "latest").images[0].digest' | head -1)
      # If 'latest' tag has a digest, find the first non-latest tag with the same digest
      if [[ -n "$latest_digest" ]]; then
          local non_latest_tag=$(curl -sL "$tags_api" | jq -r --arg digest "$latest_digest" '.results[] | select(.name != "latest" and .images[0].digest == $digest).name' | head -1)
          echo "$non_latest_tag"
      else
          # If 'latest' tag does not exist or has no digest, get the most recent tag
          local most_recent_tag=$(curl -sL "$tags_api" | jq -r '.results[] | .name' | head -1)
          echo "$most_recent_tag"
      fi
  fi
}

# ---- Validate Input Arguments ----
# Check for command-line arguments
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments provided."
    echo "Usage: $0 <instrumentation-library-name> [--debug]"
    exit 1
fi

# ---- Initialize Variables ----
# Set the YAML file path and the YAML value path
setd "YAML_FILE_PATH" "$1"
setd "YAML_VALUE_PATH" "$2"

# Determine the type of the value at YAML_VALUE_PATH
if [[ "$YAML_VALUE_PATH" =~ ^select\(.*\) || "$YAML_VALUE_PATH" =~ ^\..* ]]; then
  # The YAML_VALUE_PATH is a complex yq expression or a direct path starting with a dot
  # Use 'eval_all' to iterate over all documents in the YAML file
  value_type="$(yq eval-all "${YAML_VALUE_PATH} | type" "${YAML_FILE_PATH}")"
else
  # The YAML_VALUE_PATH is a direct path without a leading dot, so prepend one
  # Use 'eval_all' to iterate over all documents in the YAML file
  value_type="$(yq eval-all ".${YAML_VALUE_PATH} | type" "${YAML_FILE_PATH}")"
fi
debug value_type

# Check the obtained value type for the specified path
if [[ "$value_type" == *'str'* ]]; then
  # If it's a string, we assume it's a Docker image reference and parse the repository and tag from it
  setd "DOCKER_IMAGE_REF" "$(yq eval "${YAML_VALUE_PATH}" "${YAML_FILE_PATH}")"
  setd "IMAGE_REPOSITORY" "${DOCKER_IMAGE_REF%:*}"
  setd "TAG_LOCAL" "${DOCKER_IMAGE_REF##*:}"
elif [[ "$value_type" == *'map'* ]]; then
  # If it's a map, we assume it contains 'repository' and 'tag'
  setd "IMAGE_REPOSITORY" "$(yq eval "${YAML_VALUE_PATH}.repository" "${YAML_FILE_PATH}")"
  setd "TAG_LOCAL" "$(yq eval "${YAML_VALUE_PATH}.tag" "${YAML_FILE_PATH}")"
else
  echo "Error: Unsupported type encountered: $value_type"
  exit 1
fi

# Handle special case for networkExplorer
if [[ "$YAML_VALUE_PATH" =~ networkExplorer ]]; then
  IMAGE_REPOSITORY="$IMAGE_REPOSITORY/splunk-network-explorer-kernel-collector"
fi

# ---- Fetch Latest Version ----
# Fetch the latest version from the appropriate repository
setd "TAG_UPSTREAM" "$(get_latest_tag "$IMAGE_REPOSITORY")"
# Check if the TAG_UPSTREAM is empty or null
if [[ -z "$TAG_UPSTREAM" || "$TAG_UPSTREAM" == "null" ]]; then
  echo "Error: Unable to retrieve the latest tag for $IMAGE_REPOSITORY"
  exit 1
fi

# ---- Display Version Information ----
# Display current and latest versions
echo "${IMAGE_REPOSITORY} -> Local tag: ${TAG_LOCAL}, Latest tag: $TAG_UPSTREAM"

# ---- Update Version Information ----
# If needed, update the tag version in values.yaml
NEED_UPDATE="${NEED_UPDATE:-0}"  # Sets NEED_UPDATE to its current value or 0 if not set
if [ "$TAG_UPSTREAM" == "$TAG_LOCAL" ]; then
  echo "We are already up to date. Nothing else to do."
elif [[ -z "$TAG_LOCAL" || "$TAG_LOCAL" == "null" || "$TAG_LOCAL" != "$TAG_UPSTREAM" ]]; then
  debug "Upserting value for ${IMAGE_REPOSITORY}:${TAG_LOCAL}"

  # Calculate the offset to correct line numbers due to comments and blanks at the start of the values.yaml.
  VALUES_FILE_START_OFFSET=$(( $(grep -nE '^[^#]' "$YAML_FILE_PATH" | head -1 | cut -d: -f1) - 1 ))
  setd "VALUES_FILE_START_OFFSET" "$VALUES_FILE_START_OFFSET"

  # Determine the line number of the tag within the YAML structure, adjusted for the file's starting offset.
  # Check if the YAML_VALUE_PATH is a complex query or a direct path
  if [[ "$YAML_VALUE_PATH" =~ ^select\(.*\) || "$YAML_VALUE_PATH" =~ ^\..* ]]; then
    # The YAML_VALUE_PATH is a complex yq expression or a direct path starting with a dot
    # Use 'eval_all' to iterate over all documents in the YAML file
    setd "RELATIVE_LINE_NUM" "$(yq eval-all "${YAML_VALUE_PATH} | line" "${YAML_FILE_PATH}")"
  else
    # The YAML_VALUE_PATH is a direct path without a leading dot, so prepend one
    # Use 'eval_all' to iterate over all documents in the YAML file
    setd "RELATIVE_LINE_NUM" "$(yq eval-all ".${YAML_VALUE_PATH} | line" "${YAML_FILE_PATH}")"
  fi
  LINE_NUM=$(( RELATIVE_LINE_NUM + VALUES_FILE_START_OFFSET ))
  setd "LINE_NUM" "$LINE_NUM"

  awk -v LINE_NUM="$LINE_NUM" -v CURRENT_TAG="$TAG_LOCAL" -v NEW_TAG="$TAG_UPSTREAM" '
    NR == LINE_NUM {
      # Replace only the CURRENT_TAG with NEW_TAG, preserving the rest of the line
      gsub(CURRENT_TAG, NEW_TAG)
    }
    { print }' "${YAML_FILE_PATH}" > temp_file.yaml && mv temp_file.yaml "${YAML_FILE_PATH}"

  NEED_UPDATE=1  # Setting NEED_UPDATE to 1 as an update is required
  debug "Tag updated from $TAG_LOCAL to $TAG_UPSTREAM, NEED_UPDATE set to $NEED_UPDATE"

  # Emit the output for the updated tags
  emit_output "TAG_LOCAL"
  emit_output "TAG_UPSTREAM"
fi

# Emit the NEED_UPDATE variable to either GitHub output or stdout
emit_output "NEED_UPDATE"

echo "Image update process completed successfully!"
exit 0
