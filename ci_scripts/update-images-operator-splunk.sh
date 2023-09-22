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
source "$SCRIPT_DIR/common.sh"

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
# Create a temporary file to hold a subsection of the values.yaml file
setd "TEMP_VALUES_FILE" "$SCRIPT_DIR/temp_values_subsection.yaml"

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
if [ "$TAG_UPSTREAM" == "$TAG_LOCAL" ]; then
  echo "We are already up to date. Nothing else to do."
  exit 0
fi
echo "We are not up to date. Updating now."
setd "NEED_UPDATE" 1
emit_output "TAG_LOCAL"
emit_output "TAG_UPSTREAM"

# ---- Extract Subsection for Update ----
# Extract the content between "# Auto-instrumentation Libraries (Start)" and "# Auto-instrumentation Libraries (End)"
awk '/# Auto-instrumentation Libraries \(Start\)/,/# Auto-instrumentation Libraries \(End\)/' "$VALUES_FILE_PATH" | grep -v "# Auto-instrumentation Libraries " > "$TEMP_VALUES_FILE"

# ---- Update Image Information ----
yq eval -i ".${TAG_LOCAL_PATH} = \"$TAG_UPSTREAM\"" "${VALUES_FILE_PATH}"
awk '
  !p && !/# Auto-instrumentation Libraries \(Start\)/ && !/# Auto-instrumentation Libraries \(End\)/ { print $0; next }
  /# Auto-instrumentation Libraries \(Start\)/ {p=1; print $0; next}
  /# Auto-instrumentation Libraries \(End\)/ {p=0; while((getline line < "'$TEMP_VALUES_FILE'") > 0) printf "      %s\n", line; print $0; next}
' "$VALUES_FILE_PATH" > "${VALUES_FILE_PATH}.updated"
# Replace the original values.yaml with the updated version
mv "${VALUES_FILE_PATH}.updated" "$VALUES_FILE_PATH"
# Cleanup temporary files
rm "$TEMP_VALUES_FILE"

# Emit the NEED_UPDATE variable to either GitHub output or stdout
emit_output "NEED_UPDATE"
# If in a CI/CD pipeline, setup git config for the bot user
setup_git

echo "Image update process completed successfully!"
exit 0
