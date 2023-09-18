#!/bin/bash

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Get the name of the remote repository (usually 'origin')
remote=$(git for-each-ref --format '%(upstream:short)' $(git symbolic-ref -q HEAD) | sed -Ee 's@^.*/([^/]*)@\1@')

# Initialize variables to keep track of changes
helm_chart_updated=0
rendered_manifests_updated=0
chloggen_file_present=0

# Only proceed if the remote repository is 'origin', indicating it's likely a PR
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    # Loop through each file in the commit
    for file in "$@"; do
        # Check if any Helm chart templates are updated
        if [[ $file == path/to/helm/chart/templates/* ]]; then
            helm_chart_updated=1
        fi

        # Check if files under ./examples/*/rendered_manifests are updated
        if [[ $file == ./examples/*/rendered_manifests/* ]]; then
            rendered_manifests_updated=1
        fi

        # Check if a .chloggen file is present
        if [[ $file == *.chloggen ]]; then
            chloggen_file_present=1
        fi
    done

    # If Helm chart or rendered manifests are updated, ensure a .chloggen file is present
    if [[ $helm_chart_updated -eq 1 ]] || [[ $rendered_manifests_updated -eq 1 ]]; then
        if [[ $chloggen_file_present -eq 0 ]]; then
            echo "A changelog entry (.chloggen) is required for this commit."
            exit 1
        fi
    fi
fi

echo "Successfully validated any required changelog entries exist for a PR."
exit 0
