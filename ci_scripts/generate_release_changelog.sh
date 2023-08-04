#!/bin/bash
# This script generates a changelog for the Splunk OpenTelemetry Collector Chart release.
# It reads the component version information from a CSV file and generates a markdown
# formatted changelog. The changelog includes the version number, release date,
# and the component versions. The changelog is then inserted into the existing
# CHANGELOG.md file, replacing the '## Unreleased' placeholder.
# This allows for an easy and standardized way to keep track of changes
# between different versions of the chart.

# Use the environment variables VERSION and DATE
VERSION=${VERSION:-default_version}
DATE=${DATE:-default_date}

$(CHLOGGEN) update --version "[$(VERSION)] - $(DATE)"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CHANGELOG_FILE="$SCRIPT_DIR/../CHANGELOG.md"
COMPONENT_VERSIONS_FILE="$SCRIPT_DIR/resources/component-versions.csv"
NEW_CONTENT="##  [$VERSION] - $DATE## [v$VERSION] - $DATE\n\nThis Splunk OpenTelemetry Collector Chart for Kubernetes release adopts the following components\n"

# Add subcontext to the release "[$VERSION] - $DATE" below
awk -v var="$NEW_CONTENT" "/##  [$VERSION] - $DATE/{print var; next} 1" $CHANGELOG_FILE > tmp && mv tmp $CHANGELOG_FILE
