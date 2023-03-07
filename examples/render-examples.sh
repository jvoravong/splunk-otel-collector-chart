#!/usr/bin/env bash
# Render all the examples in parallel

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

render_task(){
  example_dir=$1
  rendered_manifests_dir="${example_dir}rendered_manifests"
	values_yaml=$example_dir`ls "${example_dir}" | grep values.yaml`

  # Clear out all rendered manifests
  rm -rf "${rendered_manifests_dir}"

  helm template \
    --namespace default \
    --values "${values_yaml}" \
    --output-dir "${rendered_manifests_dir}" \
    default helm-charts/splunk-otel-collector &>/dev/null
  if [ $? -ne 0 ]; then
      echo $values_yaml FAIL
      exit 1
  fi
  # Move the chart renders.
	cp -rp "${rendered_manifests_dir}/splunk-otel-collector/templates/"* $rendered_manifests_dir;
  if [ $? -ne 0 ]; then
      echo "${values_yaml}" FAIL
      exit 1
  fi
  # Move any subchart renders.
  if [ -d "${rendered_manifests_dir}/splunk-otel-collector/charts/" ]
  then
    subcharts_dir="${example_dir}rendered_manifests/splunk-otel-collector/charts"; \
    subcharts_di=$(find "${subcharts_dir}" -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
    for subchart in ${subcharts_di}; do \
      mkdir -p "${example_dir}rendered_manifests/${subchart}"; \
      mv "${subcharts_dir}/${subchart}/templates/"* "${example_dir}rendered_manifests/${subchart}"; \
      if [ $? -ne 0 ]; then
          echo "${values_yaml}" FAIL
          exit 1
      fi
    done; \
  fi
  # Delete dir used as temporary space.
	rm -rf "${rendered_manifests_dir}/splunk-otel-collector"
  if [ $? -ne 0 ]; then
      echo "${values_yaml}" FAIL
      exit 1
  fi

  echo "${values_yaml}" SUCCESS
}

for example_dir in $SCRIPT_DIR/*/; do
  render_task "${example_dir}" &
done
wait # Let all the render tasks finish

for example_dir in $SCRIPT_DIR/*/; do
  rendered_manifests_dir=$example_dir"rendered_manifests"
  if [ ! -d "${rendered_manifests_dir}" ]; then
    echo "Examples were rendered, failure occurred"
    exit 1
  fi
done

echo "Examples were rendered successfully"
exit 0
