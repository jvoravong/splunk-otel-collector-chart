# Variables
VERSION ?= 0.84.0
DATE = $(shell date +%Y-%m-%d)
KUTTL=$(shell which kubectl-kuttl)
CHANGELOG_LINE="\n\nThis Splunk OpenTelemetry Collector for Kubernetes release adopts the [Splunk OpenTelemetry Collector v${VERSION}].\n"
LOCALBIN ?= $(shell pwd)/bin
KUBE_VERSION ?= 1.27
KIND_CONFIG ?= test/kind-$(KUBE_VERSION).yaml

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
  source ci_scripts/.env ;\
  bash ci_scripts/deploy_chart_target_splunk_platform.sh ;\
  bash ci_scripts/deploy_splunk.sh ;\
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
