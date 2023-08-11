#!/bin/bash
set -e

# Constants
TIMEOUT=300

# Function to wait with timeout
wait_with_timeout() {
    local start_time=$SECONDS
    local condition=$1
    local timeout_msg=$2

    until eval "$condition"; do
        if [ $(($SECONDS - $start_time)) -ge $TIMEOUT ]; then
            echo "$timeout_msg"
            exit 1
        fi
        echo -n "."
        sleep 5
    done
    echo
}

# Wait until default service account is created
wait_with_timeout "kubectl -n default get serviceaccount default -o name" "Timeout waiting for default service account."

# Install Splunk on minikube
kubectl apply -f ci_scripts/k8s-splunk.yml

# Wait until splunk is ready
wait_with_timeout "kubectl get pods; kubectl logs splunk --tail=2 | grep -q 'Ansible playbook complete'" "Timeout waiting for Splunk readiness."
sleep 10

export CI_SPLUNK_HOST=$(kubectl get pod splunk --template={{.status.podIP}})

# Helper function for CURL commands
splunk_curl() {
    curl -k -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD "$@"
}

# Setup Indexes
splunk_curl -X POST "https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes" -d "name=$CI_INDEX_EVENTS" -d datatype=event
splunk_curl -X POST "https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes" -d name=ns-anno -d datatype=event
splunk_curl -X POST "https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes" -d name=pod-anno -d datatype=event
splunk_curl -X POST "https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes" -d "name=$CI_INDEX_METRICS" -d datatype=metric

# Enable HEC services
splunk_curl -X POST "https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/servicesNS/nobody/splunk_httpinput/data/inputs/http/http/enable"

# Create new HEC token
splunk_curl -X POST -d "name=splunk_hec_token&token=$CI_SPLUNK_PASSWORD&disabled=0&index=main&indexes=main,ci_events,ci_metrics,ns-anno,pod-anno" "https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/servicesNS/nobody/splunk_httpinput/data/inputs/http"

# Restart Splunk
splunk_curl -X POST "https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/server/control/restart"
