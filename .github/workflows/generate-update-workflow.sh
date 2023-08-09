#!/bin/bash

# List of jobs to search for
declare -a job_names=("pre-commit" "lint-test" "validate-changelog" "maybe_update_chart" "maybe_update_instrumentation" "e2e-test")

# Start of the generated workflow
cat <<EOL > combined_workflow.yaml
name: Check for new chart dependency updates

on:
  schedule:
    # Run every Monday at noon.
    - cron: "0 12 * * 1"
  workflow_dispatch:

jobs:
EOL

# Iterate over the job names
for job in "${job_names[@]}"; do
    # Iterate over all YAML files in the directory for each job
    for file in *.yaml; do
        # Check if it's not the generated workflow
        if [[ "$file" != "combined_workflow.yaml" ]]; then
            # Extract the job using yq
            job_content=$(yq e ".jobs.${job}" "$file")
            # Check if the job content is not null before appending
            if [[ "$job_content" != "null" && -n "$job_content" ]]; then
                # Write the job name and then append the indented content
                echo "  ${job}:" >> combined_workflow.yaml
                echo "$job_content" | sed 's/^/    /' >> combined_workflow.yaml
                echo "" >> combined_workflow.yaml
            fi
        fi
    done
done



