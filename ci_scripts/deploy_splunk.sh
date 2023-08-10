#!/bin/bash

# Wait until default service account is created
until kubectl -n default get serviceaccount default -o name; do
  sleep 1;
done

# Install Splunk on minikube
kubectl apply -f ci_scripts/k8s-splunk.yml

# Wait until splunk is ready
until kubectl logs splunk --tail=2 | grep -q 'Ansible playbook complete'; do
  sleep 2;
done

export CI_SPLUNK_HOST=$(kubectl get pod splunk --template={{.status.podIP}})

# Setup Indexes
curl -k -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes -d name=$CI_INDEX_EVENTS -d datatype=event
curl -k -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes -d name=ns-anno -d datatype=event
curl -k -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes -d name=pod-anno -d datatype=event
curl -k -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/data/indexes -d name=$CI_INDEX_METRICS -d datatype=metric

# Enable HEC services
curl -X POST -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD -k https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/servicesNS/nobody/splunk_httpinput/data/inputs/http/http/enable

# Create new HEC token
curl -X POST -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD -k -d "name=splunk_hec_token&token=a6b5e77f-d5f6-415a-bd43-930cecb12959&disabled=0&index=main&indexes=main,ci_events,ci_metrics,ns-anno,pod-anno" https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/servicesNS/nobody/splunk_httpinput/data/inputs/http

# Restart Splunk
curl -k -u $CI_SPLUNK_USERNAME:$CI_SPLUNK_PASSWORD https://$CI_SPLUNK_HOST:$CI_SPLUNK_PORT/services/server/control/restart -X POST
