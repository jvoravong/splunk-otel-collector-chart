# Variables
VERSION ?= 0.84.0
DATE = $(shell date +%Y-%m-%d)
KUTTL=$(shell which kubectl-kuttl)
CHANGELOG_LINE="\n\nThis Splunk OpenTelemetry Collector for Kubernetes release adopts the [Splunk OpenTelemetry Collector v${VERSION}].\n"
LOCALBIN ?= $(shell pwd)/bin
KUBE_VERSION ?= 1.27
KIND_CONFIG ?= test/kind-$(KUBE_VERSION).yaml

# Splunk configuration for CI environment.
# Port for the Splunk instance.
export CI_SPLUNK_PORT=${CI_SPLUNK_PORT:-8089}
# Username for Splunk authentication.
export CI_SPLUNK_USERNAME=${CI_SPLUNK_USERNAME:-admin}
# Splunk HTTP Event Collector (HEC) token.
export CI_SPLUNK_HEC_TOKEN=${CI_SPLUNK_HEC_TOKEN:-a6b5e77f-d5f6-415a-bd43-930cecb12959}
# Password for Splunk authentication.
export CI_SPLUNK_PASSWORD=${CI_SPLUNK_PASSWORD:-helloworld}
# Splunk index for CI events.
export CI_INDEX_EVENTS=${CI_INDEX_EVENTS:-ci_events}
# Splunk index for CI metrics.
export CI_INDEX_METRICS=${CI_INDEX_METRICS:-ci_metrics}

# Configuration for container runtime and Kubernetes.
# Specifies the container runtime used in the CI environment.
export CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
# Version of Kubernetes to be used.
export KUBERNETES_VERSION=${KUBERNETES_VERSION:-v1.21.2}
# Version of Minikube to be used.
export MINIKUBE_VERSION=${MINIKUBE_VERSION:-v1.22.0}
# Host URL for the Splunk service within Kubernetes.
export CI_SPLUNK_HOST=${CI_SPLUNK_HOST:-splunk-service.default.svc.cluster.local}

# Default help target
.DEFAULT_GOAL := help

##@ Setup
.PHONY: install-tools
install-tools: sync_files ## Check and install necessary tools
	@which helm > /dev/null || (echo "Installing Helm..." && curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash)

.PHONY: repo-update
repo-update: ## Update the Helm repository
	@{ \
	if ! (helm repo list | grep -q open-telemetry) ; then \
		helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts ;\
	fi ;\
	if ! (helm repo list | grep -q jetstack) ; then \
		helm repo add jetstack https://charts.jetstack.io ;\
	fi ;\
	helm repo update open-telemetry jetstack ;\
	}

.PHONY: dep-build
dep-build: ## Build Helm dependencies
	@{ \
  OK=true ;\
  DIR=helm-charts/splunk-otel-collector ;\
	if ! helm dependencies list $$DIR | grep open-telemetry | grep -q ok ; then OK=false ; fi ;\
	if ! helm dependencies list $$DIR | grep jetstack | grep -q ok ; then OK=false ; fi ;\
	if ! $$OK ; then helm dependencies build $$DIR ; fi ;\
	}

.PHONY: $(LOCALBIN)
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

##@ Deployment
.PHONY: deploy_chart_with_with ##
deploy_sck_otel_collector:

.PHONY: deploy_log_generator
deploy_log_generator:
	@bash ci_scripts/deploy_log_generator.sh

.PHONY: run_functional_tests
run_functional_tests:

##@ Tests
.PHONY: e2e
e2e: ## Run end-to-tests
	@#bash scripts/run_functional_tests.sh
	$(KUTTL) test --config test/kuttl-test.yaml

.PHONY: prepare-e2e
prepare-e2e: render start-kind ## Prepare end-to-end tests, deploys Deploy this chart and Splunk Platform (https://hub.docker.com/r/splunk/splunk/)
	@{ \
  bash ci_scripts/deploy_chart_target_splunk_platform.sh ;\
	}

.PHONY: clean-e2e
clean-e2e: ## Delete kind cluster
	kind delete cluster

.PHONY: start-kind
start-kind: ## Start kind cluster
	if kind get clusters | grep kind; then \
		echo "kind cluster has already been created"; \
	else \
		kind create cluster --config $(KIND_CONFIG); \
	fi

##@ Helpers
.PHONY: render
render: install-tools repo-update dep-build ## Render examples
	bash ./examples/render-examples.sh

.PHONY: sync_files # Download files from upstream GitHub repositories and save them to a specified location
sync_files:
	./ci_scripts/sync_github_files.sh "https://github.com/open-telemetry/opentelemetry-operator/blob/main/hack/install-kuttl.sh" "./hack"
	./ci_scripts/sync_github_files.sh "https://github.com/open-telemetry/opentelemetry-operator/blob/main/hack/install-metrics-server.sh" "./hack"
	./ci_scripts/sync_github_files.sh "https://github.com/open-telemetry/opentelemetry-operator/blob/main/kind-*.yaml" "./test"

# Help target to display target descriptions
.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
