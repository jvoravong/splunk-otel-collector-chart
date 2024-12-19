#!/bin/bash
echo "Checking if 'Instrumentation' CRD is available..."
for i in $(seq 1 300); do
  if kubectl get otelinst >/dev/null 2>&1; then
    echo "'Instrumentation' CRD is available."
    exit 0
  fi
  echo "Waiting for 'Instrumentation' CRD to become available... (attempt $i)"
  sleep 1
done
echo "Timeout reached. 'Instrumentation' CRD did not become available."
exit 1
