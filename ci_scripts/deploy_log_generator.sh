#!/bin/bash
set -e

kubectl apply -f test/test_setup.yaml
sleep 60
kubectl get pods --all-namespaces
kubectl logs -l component=agent-collector
