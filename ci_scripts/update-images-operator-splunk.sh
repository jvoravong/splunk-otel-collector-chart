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
#   ./update-images-operator-splunk.sh nodejs --debug

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

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
NEED_UPDATE="${NEED_UPDATE:-0}"  # Sets NEED_UPDATE to its current value or 0 if not set
if [ "$TAG_UPSTREAM" == "$TAG_LOCAL" ]; then
  echo "We are already up to date. Nothing else to do."
elif [[ -z "$TAG_LOCAL" || "$TAG_LOCAL" == "null" || "$TAG_LOCAL" != "$TAG_UPSTREAM" ]]; then
  debug "Upserting value for ${REPOSITORY_LOCAL}:${TAG_LOCAL}"

  # Calculate the offset to correct line numbers due to comments and blanks at the start of the values.yaml.
  VALUES_FILE_START_OFFSET=$(( $(grep -nE '^[^#]' "$VALUES_FILE_PATH" | head -1 | cut -d: -f1) - 1 ))
  setd "VALUES_FILE_START_OFFSET" "$VALUES_FILE_START_OFFSET"

  # Determine the line number of the tag within the YAML structure, adjusted for the file's starting offset.
  RELATIVE_LINE_NUM=$(yq eval ".${TAG_LOCAL_PATH} | line" "${VALUES_FILE_PATH}")
  LINE_NUM=$(( RELATIVE_LINE_NUM + VALUES_FILE_START_OFFSET ))
  setd "LINE_NUM" "$LINE_NUM"

  # Replace only the tag value on the identified line, preserving the existing formatting and indentation.
  awk -v LINE_NUM="$LINE_NUM" -v NEW_TAG="$TAG_UPSTREAM" 'NR == LINE_NUM {sub(/tag: .+$/, "tag: " NEW_TAG "")} 1' "${VALUES_FILE_PATH}" > temp_file.yaml && mv temp_file.yaml "${VALUES_FILE_PATH}"

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
