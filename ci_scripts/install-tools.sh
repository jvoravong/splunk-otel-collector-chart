#!/bin/bash
# Purpose: Installs or upgrades essential development tools.
# Notes:
#   - Supports macOS and Linux (best effort) for installations via Homebrew.
#   - Installs tools like kubectl, helm, pre-commit, go, and chloggen.
#   - Use OVERRIDE_OS_CHECK=true to bypass OS compatibility checks.
#   - This script is intended to be run via `make install-tools`.
#
# Example Usage:
#   Directly with bash: ./install-tools.sh [OVERRIDE_OS_CHECK=true]
#   Via make action: make install-tools [OVERRIDE_OS_CHECK=true]

# Function to install or upgrade a tool
install_or_upgrade() {
  local tool=$1
  local install_cmd=$2
  local upgrade_cmd=$3

  if $install_cmd >/dev/null 2>&1; then
    read -p "$tool is already installed. Would you like to upgrade it? (y/n): " yn
    case $yn in
      [Yy]* )
        echo "Upgrading $tool..."
        $upgrade_cmd || echo "Failed to upgrade $tool. Continuing..."
        ;;
      [Nn]* )
        echo "Skipping upgrade for $tool."
        ;;
      * )
        echo "Please answer yes or no."
        exit 1
        ;;
    esac
  else
    read -p "$tool is not installed. Would you like to install it? (y/n): " yn
    case $yn in
      [Yy]* )
        echo "Installing $tool..."
        $install_cmd || echo "Failed to install $tool. Continuing..."
        ;;
      [Nn]* )
        echo "Skipping install for $tool."
        ;;
      * )
        echo "Please answer yes or no."
        exit 1
        ;;
    esac
  fi
}

# Check the operating system or bypass with OVERRIDE_OS_CHECK
if [ "$OVERRIDE_OS_CHECK" != "true" ]; then
  UNAME_S=$(uname -s)
  if [ "$UNAME_S" != "Darwin" ] && [ "$UNAME_S" != "Linux" ]; then
    echo "This script currently only supports macOS and Linux (with best effort)."
    exit 1
  fi
fi

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. This script currently only supports Homebrew."
  read -p "Would you like to install Homebrew? (y/n): " yn
  case $yn in
    [Yy]* )
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "Failed to install Homebrew. Please install it manually."
        exit 1
      }
      ;;
    [Nn]* )
      exit 1
      ;;
    * )
      echo "Please answer yes or no."
      exit 1
      ;;
  esac
fi

# Install or upgrade brew-based tools
for tool in kubectl helm pre-commit go; do
  install_or_upgrade "$tool" "brew list $tool" "brew upgrade $tool"
done

# Install or upgrade chloggen
install_or_upgrade "chloggen" "[ -f \"$LOCALBIN/chloggen\" ]" "GOBIN=$LOCALBIN go install go.opentelemetry.io/build-tools/chloggen@v0.11.0"

echo "Tool installation and upgrade process completed successfully!"
exit 0
