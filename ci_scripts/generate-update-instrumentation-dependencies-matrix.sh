#!/bin/bash

# Include the base utility functions for setting and debugging variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/base_util.sh"

get_latest_tag() {
    local repo_value="$1"

    # For quay.io
    if [[ "$repo_value" =~ ^quay\.io/([^/]+)(/([^/]+))?$ ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo_name="${BASH_REMATCH[3]}"
        local latest_api="https://quay.io/api/v1/repository/$owner/$repo_name/tag/?limit=1&onlyActiveTags=true"
        echo $(curl -sL "$latest_api" | jq -r '.tags[0].name')

    # For ghcr.io
    elif [[ "$repo_value" =~ ^ghcr\.io/([^/]+)/([^/]+)/([^/]+)$ ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo_name="${BASH_REMATCH[2]}"
        local latest_api="https://api.github.com/repos/${owner}/${repo_name}/tags"
        echo $(curl -sL -qs -H 'Accept: application/vnd.github+json' "$latest_api" | jq -r '.[0].name')

    # Default for Docker Hub
    else
        local latest_api="https://registry.hub.docker.com/v2/repositories/$repo_value/tags/?page_size=2"  # Fetch only the two latest tags
        echo $(curl -sL "$latest_api" | jq -r '.results[] | select(.name != "latest") | .name')
    fi
}

values_file="$SCRIPT_DIR/../helm-charts/splunk-otel-collector/values.yaml"
setd "YAML_FILE_START_OFFSET" "$(grep -nE '^[^#]' "$values_file" | head -1 | cut -d: -f1)"

# Get all paths that lead to a 'repository'
setd "repository_paths" "$(yq e '.. | select(has("repository") and has("tag")) | path | join(".")' "$values_file")"

# Initialize matrix variable
matrix="matrix: { include: ["

IFS=$'\n'
for path in $repository_paths; do
    setd "repository_value" "$(yq e ".$path.repository" "$values_file")"
    setd "current_tag" "$(yq e ".$path.tag" "$values_file")"

    # Skip if the current_tag is empty or "latest"
    if [[ -z "$current_tag" || "$current_tag" == "latest" ]]; then
        continue
    # The operator subchart must be in lock step with images prefixed with autoinstrumentation-*
    # Skip if repository_value starts with "autoinstrumentation-"
    elif [[ "$repository_value" =~ autoinstrumentation- ]]; then
        continue
    fi

    # Check if the current tag matches the latest version
    # The network explorer is a special case for how to update the involved images
    if [[ "$path" =~ networkExplorer ]]; then
      latest_tag=$(get_latest_tag "${repository_value}/splunk-network-explorer-kernel-collector")
    else
      latest_tag=$(get_latest_tag "$repository_value")
    fi

    if [[ "$current_tag" != "$latest_tag" ]]; then
        # Extract line number using yq for the tag query
        tag_line=$(( $(yq -e ".$path.tag | line" "$values_file") + YAML_FILE_START_OFFSET ))
        matrix+="\n  { path: \"$path\", repository: \"$repository_value\", current_tag: \"$current_tag\", latest_tag: \"$latest_tag\", tag_line: \"$tag_line\" },"
    fi
done

matrix+="] }"

# Now you can echo the matrix variable or use it elsewhere
echo -e "$matrix"  # Use -e option to interpret escape sequences like \n
