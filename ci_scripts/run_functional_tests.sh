#!/bin/bash

kubectl get nodes
export PYTHONWARNINGS="ignore:Unverified HTTPS request"
export CI_SPLUNK_HOST=$(kubectl get pod splunk --template={{.status.podIP}})
cd test
pip install --upgrade pip
pip install -r requirements.txt
echo "Running functional tests....."
python -m pytest \
  --splunkd-url https://$CI_SPLUNK_HOST:8089 \
  --splunk-user admin \
  --splunk-password $CI_SPLUNK_PASSWORD \
  -p no:warnings -s
