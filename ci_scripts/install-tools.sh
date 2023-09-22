#!/bin/bash
# Purpose: Installs or upgrades essential development tools.
# Notes:
#   - Should be executed via the `make install-tools` command.
#   - Supports macOS and Linux for installations via `brew install` and `go install`.
#   - Installs tools like kubectl, helm, pre-commit, go, and chloggen.
#   - Use OVERRIDE_OS_CHECK=true to bypass OS compatibility checks.
#   - Prompts the user for approval to install or update each tool.
#   - Use setd "AUTO_APPROVE" true to automatically install/upgrade all tools (useful for CI/CD).

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

# ---- Initialize Variables and Functions ----
# Default to true if running in a GitHub workflow, false otherwise
setd "AUTO_APPROVE" ${AUTO_APPROVE:-${GITHUB_ACTIONS:-1}}

# Function to ask for user approval
ask_for_approval() {
  local msg="$1"

  if [ "$AUTO_APPROVE" = 0 ]; then
    return 0
  fi

  read -p "$msg (y/n): " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

# Function to install or upgrade a tool
install_or_upgrade() {
  setd "TOOL" "$1"
  setd "TYPE" "$2"

  case $TYPE in
    brew)
      install_or_upgrade_brew "$TOOL"
      ;;
    go)
      install_or_upgrade_go "$TOOL"
      ;;
    *)
      echo "Unsupported tool type: $TYPE"
      exit 1
      ;;
  esac
}

# Function to install or upgrade a Homebrew-based tool
install_or_upgrade_brew() {
  setd "TOOL" "$1"
  setd "INSTALLED_VERSION" $(brew list --versions "$TOOL" | awk '{print $2}')
  setd "LATEST_VERSION" $(brew info --json=v1 "$TOOL" | jq -r '.[0].versions.stable')

  # Check if the tool is installed
  if [ -n "$INSTALLED_VERSION" ]; then
    # Check if the installed version is the latest
    if [ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]; then
      echo "$TOOL is already up-to-date (version $INSTALLED_VERSION)."
      return
    else
      if ask_for_approval "Upgrade $TOOL from version $INSTALLED_VERSION to $LATEST_VERSION?"; then
        brew upgrade "$TOOL" || echo "Failed to upgrade $TOOL. Continuing..."
      fi
    fi
  else
    if ask_for_approval "Install $TOOL? Latest version available: $LATEST_VERSION"; then
      brew install "$TOOL" || echo "Failed to install $TOOL. Continuing..."
    fi
  fi
}

# Function to install or upgrade a Go-based tool
install_or_upgrade_go() {
  setd "TOOL" "$1"
  TOOL_PATH="$LOCALBIN/$(basename $TOOL)"

  if [ -f "${TOOL_PATH}" ]; then
    # Right now the installed tools don't include a way to extract the actual version.
    setd "INSTALLED_VERSION" "UNKNOWN (Last updated: $(stat -c %y "$TOOL_PATH" 2>/dev/null || stat -f "%Sm" "$TOOL_PATH"))"
    setd "ACTION" "upgrade"
  else
    setd "INSTALLED_VERSION" "Not Installed"
    setd "ACTION" "install"
  fi

  if ask_for_approval "$ACTION $TOOL? Current version: \"$INSTALLED_VERSION\""; then
    GOBIN=${LOCALBIN} go install "${TOOL}@latest" || echo "Failed to $ACTION $TOOL. Continuing..."
  fi
}

# ---- Install Tools ----
# Install or upgrade brew-based tools
for TOOL in kubectl helm pre-commit go; do
  install_or_upgrade "$TOOL" brew
done

# Install or upgrade Go-based tools
install_or_upgrade "go.opentelemetry.io/build-tools/chloggen" go

echo "Tool installation and upgrade process completed successfully!"
exit 0
