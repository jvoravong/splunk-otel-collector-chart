#!/bin/bash
# Purpose: Installs or upgrades essential development tools.
# Notes:
#   - Supports macOS and Linux for installations via `brew install` and `go install`.
#   - Installs tools like kubectl, helm, pre-commit, go, and chloggen.
#   - Use OVERRIDE_OS_CHECK=true to bypass OS compatibility checks.
#   - Prompts the user for approval to install or update each tool.
#   - Use AUTO_APPROVE=true to automatically install/upgrade all tools (useful for CI/CD).
#   - Intended for `make install-tools`.
#
# Example Usage:
#   make install-tools [OVERRIDE_OS_CHECK=true] [AUTO_APPROVE=true]

# Default to true if running in a GitHub workflow, false otherwise
AUTO_APPROVE=${AUTO_APPROVE:-${GITHUB_ACTIONS:-false}}

# Function to ask for user approval
ask_for_approval() {
  local msg="$1"

  if [ "$AUTO_APPROVE" = "true" ]; then
    return 0
  fi

  read -p "$msg (y/n): " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

# Function to install or upgrade a tool
install_or_upgrade() {
  local tool="$1"
  local type="$2"

  case $type in
    brew)
      install_or_upgrade_brew "$tool"
      ;;
    go)
      install_or_upgrade_go "$tool"
      ;;
    *)
      echo "Unsupported tool type: $type"
      exit 1
      ;;
  esac
}

# Function to install or upgrade a Homebrew-based tool
install_or_upgrade_brew() {
  local tool="$1"
  local installed_version=$(brew list --versions "$tool" | awk '{print $2}')
  local latest_version=$(brew info --json=v1 "$tool" | jq -r '.[0].versions.stable')

  # Check if the tool is installed
  if [ -n "$installed_version" ]; then
    # Check if the installed version is the latest
    if [ "$installed_version" == "$latest_version" ]; then
      echo "$tool is already up-to-date (version $installed_version)."
      return
    else
      if ask_for_approval "Upgrade $tool from version $installed_version to $latest_version?"; then
        brew upgrade "$tool" || echo "Failed to upgrade $tool. Continuing..."
      fi
    fi
  else
    if ask_for_approval "Install $tool? Latest version available: $latest_version"; then
      brew install "$tool" || echo "Failed to install $tool. Continuing..."
    fi
  fi
}

# Function to install or upgrade a Go-based tool
install_or_upgrade_go() {
  local tool="$1"
  local tool_path="$LOCALBIN/$(basename $tool)"
  local action="upgrade"
  local installed_version

  if [ -f "$tool_path" ]; then
    installed_version=$("$tool" --version 2>/dev/null) || \
      installed_version="UNKNOWN (Last updated: $(stat -c %y "$tool_path" 2>/dev/null || stat -f "%Sm" "$tool_path"))"
  else
    installed_version="Not Installed"
    action="install"
  fi

  if ask_for_approval "$action $tool? Current version: \"$installed_version\""; then
    GOBIN=$LOCALBIN go install "${tool}@latest" || echo "Failed to $action $tool. Continuing..."
  fi
}

# Install or upgrade brew-based tools
for tool in kubectl helm pre-commit go; do
  install_or_upgrade "$tool" brew
done

# Install or upgrade Go-based tools
install_or_upgrade "go.opentelemetry.io/build-tools/chloggen" go

echo "Tool installation and upgrade process completed successfully!"
exit 0
