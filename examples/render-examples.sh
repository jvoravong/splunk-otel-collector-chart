#!/usr/bin/env bash
# Render all the examples in parallel

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

render_task(){
  example_dir=$1
  rendered_manifests_dir=$(echo $example_dir | sed -e "s/examples/examples\\/rendered_manifests/g")
	values_yaml=$example_dir`ls $example_dir | grep yaml`

  # Clear out all rendered manifests
  rm -rf $rendered_manifests_dir

  helm template \
    --namespace default \
    --values $values_yaml \
    --output-dir $rendered_manifests_dir \
    default helm-charts/splunk-otel-collector &>/dev/null

  if [ $? -ne 0 ]; then
      echo $values_yaml FAIL
      exit 1
  fi
	cp -rp $rendered_manifests_dir"/splunk-otel-collector/templates/"* $rendered_manifests_dir;
  if [ $? -ne 0 ]; then
      echo $values_yaml FAIL
      exit 1
  fi
	rm -rf $rendered_manifests_dir"/splunk-otel-collector"
  if [ $? -ne 0 ]; then
      echo $values_yaml FAIL
      exit 1
  fi

  echo $values_yaml SUCCESS
}

for example_dir in $SCRIPT_DIR/*/; do
  if [[ ! "$example_dir" == *"rendered_manifests"* ]]; then
    render_task $example_dir &
  fi
done
wait # Let all the render tasks finish

for example_dir in $SCRIPT_DIR/*/; do
  rendered_manifests_dir=$(echo $example_dir | sed -e "s/examples/examples\\/rendered_manifests/g")
  if [[ ! "$example_dir" == *"rendered_manifests"* ]]; then
    if [ ! -d $rendered_manifests_dir ]; then
      echo "Examples were rendered, failure occurred"
      exit 1
    fi
  fi
done

examples_md=$SCRIPT_DIR/examples.md
rm $examples_md
touch $examples_md


echo "<details open>" >> $examples_md
echo "<summary>Want to ruin the surprise?</summary>" >> $examples_md
echo "<br>" >> $examples_md
echo "you asked for it!" >> $examples_md
echo "</details>" >> $examples_md



for example_dir in $SCRIPT_DIR/*/; do
  rendered_manifests_dir=$(echo $example_dir | sed -e "s/examples/examples\\/rendered_manifests/g")
  if [[ ! "$example_dir" == *"rendered_manifests"* ]]; then
    if [ ! -d $rendered_manifests_dir ]; then
      echo "Examples were rendered, failure occurred"

    fi
  fi
done

echo "Examples were rendered successfully"
exit 0
