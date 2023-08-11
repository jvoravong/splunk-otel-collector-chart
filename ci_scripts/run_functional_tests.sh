#!/bin/bash
set -e
source ./.env

kubectl get nodes
export PYTHONWARNINGS="ignore:Unverified HTTPS request"
cd test
pip install --upgrade pip
pip install -r requirements.txt
echo "Running functional tests....."
python -m pytest \
  --splunkd-url https://http://splunk-service.default:8089 \
  --splunk-user admin \
  --splunk-password $CI_SPLUNK_PASSWORD \
  -p no:warnings -s
