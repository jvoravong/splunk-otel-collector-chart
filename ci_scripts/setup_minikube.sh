#!/bin/bash

# Install Kubectl
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
mkdir -p ${HOME}/.kube
touch ${HOME}/.kube/config

# Install Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/
sudo sysctl fs.protected_regular=0

# Start Minikube and Wait
minikube start --container-runtime=${CONTAINER_RUNTIME} --cpus 2 --memory 4096 --kubernetes-version=${KUBERNETES_VERSION} --no-vtx-check
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
export JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do
  sleep 1;
done
