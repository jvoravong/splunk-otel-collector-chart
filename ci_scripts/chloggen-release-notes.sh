#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# Extract the version difference from Chart.yaml
VERSION_DIFF=$(git diff HEAD^ -- "*Chart.yaml" | grep -E "^\+version:" || echo "")
if [[ ! -z "$VERSION_DIFF" ]]; then
  # Extract the new version number
  NEW_VERSION=$(echo "$VERSION_DIFF" | awk '{print $2}')
  # Escape dots for regex, as they are special characters
  ESCAPED_VER=$(echo $NEW_VERSION | sed 's/\./\\./g')
  # Create the search pattern with escaped brackets and version number
  VER_PATTERN="\[${ESCAPED_VER}\]"

  echo "Extracting release notes for version $NEW_VERSION"
  # Use awk to extract the release notes for the specified version
  awk "\$0 ~ /$VER_PATTERN/,/^## \[/{if (\$0 ~ /^## \[/ && \$0 !~ /$VER_PATTERN/) exit; else print}" CHANGELOG.md > RELEASE.md

  echo "RELEASE_NOTES_PATH=RELEASE.md" >> $GITHUB_ENV
  echo "NEW_VERSION=$NEW_VERSION" >> $GITHUB_ENV
else
  echo "No new release needed"
fi
