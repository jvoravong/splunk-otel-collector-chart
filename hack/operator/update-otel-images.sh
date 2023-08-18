#!/bin/bash

set -e  # Exit script if any command fails

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHART_PATH="$SCRIPT_DIR/../..//helm-charts/splunk-otel-collector/Chart.yaml"
VALUES_PATH="$SCRIPT_DIR/../..//helm-charts/splunk-otel-collector/values.yaml"
TEMP_SUBSECTION="$SCRIPT_DIR/temp_subsection.yaml"

# Extract the subsection between "operator:" and just before "cert-manager:" to a temporary file
awk '/^operator:/,/^\s*$/' $VALUES_PATH | grep -v "^cert-manager:" > $TEMP_SUBSECTION

# Update the subsection using your yq logic
while IFS='=' read -r image_key version; do
    if [[ $image_key =~ ^autoinstrumentation-.* ]]; then
        actual_key="${image_key#autoinstrumentation-}"
        image_name="ghcr.io/open-telemetry/opentelemetry-operator/$image_key:$version"
        yaml_path="operator.instrumentation.spec.${actual_key}.image"
        existing_value=$(yq eval ".${yaml_path}" $TEMP_SUBSECTION)
        if [[ "$existing_value" != "null" && "$existing_value" == *"splunk"* ]]; then
            echo "Retaining existing value for $yaml_path: $existing_value"
            continue
        fi
        echo "Updating value for $yaml_path: $existing_value"
        yq eval -i ".${yaml_path} = \"$image_name\"" $TEMP_SUBSECTION
    fi
done < versions.txt

# Merge the updated subsection back into values.yaml
awk -v start="^      # Auto-instrumentation Libraries" -v end="    certManager:" -v file="$TEMP_SUBSECTION" '
  !p && $0 !~ start && $0 !~ end { print $0; next }
  $0 ~ start {p=1; while((getline line < file) > 0) print line; next}
  $0 ~ end {p=0; print $0}
' $VALUES_PATH > "${VALUES_PATH}.updated"

# Replace the original values.yaml with the updated version
mv "${VALUES_PATH}.updated" $VALUES_PATH

# Cleanup
rm $TEMP_SUBSECTION

echo "Image update process completed successfully!"
