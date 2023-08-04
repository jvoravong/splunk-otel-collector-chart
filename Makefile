VERSION ?= 0.84.0
DATE = $(shell date +%Y-%m-%d)
CHANGELOG_LINE="\n\nThis Splunk OpenTelemetry Collector for Kubernetes release adopts the [Splunk OpenTelemetry Collector v${VERSION}].\n"
#VERSION="$(cat ./helm-charts/splunk-otel-collector/Chart.yaml | sed -nr 's/version: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p')"
#APP_VERSION = "$(cat ./helm-charts/splunk-otel-collector/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p')"
## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

KUBE_VERSION ?= 1.27
KIND_CONFIG ?= kind-$(KUBE_VERSION).yaml
CHLOGGEN ?= $(LOCALBIN)/chloggen

.PHONY: render
render: repo-update dep-build
	bash ./examples/render-examples.sh

.PHONY: repo-update
repo-update:
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
dep-build:
	@{ \
  OK=true ;\
  DIR=helm-charts/splunk-otel-collector ;\
	if ! helm dependencies list $$DIR | grep open-telemetry | grep -q ok ; then OK=false ; fi ;\
	if ! helm dependencies list $$DIR | grep jetstack | grep -q ok ; then OK=false ; fi ;\
	if ! $$OK ; then helm dependencies build $$DIR ; fi ;\
	}

.PHONY: chlog-install
chlog-install: $(CHLOGGEN)
$(CHLOGGEN): $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install go.opentelemetry.io/build-tools/chloggen@v0.3.0

FILENAME?=$(shell git branch --show-current)
.PHONY: chlog-new
chlog-new: chlog-install
	$(CHLOGGEN) new --filename $(FILENAME)

.PHONY: chlog-validate
chlog-validate: chlog-install
	$(CHLOGGEN) validate

.PHONY: chlog-preview
chlog-preview: chlog-install
	$(CHLOGGEN) update --dry

.PHONY: chlog-update
chlog-update: chlog-install
	$(CHLOGGEN) update --version "[$(VERSION)] - $(DATE)"

checkout:
	@bash scripts/checkout.sh

setup_minikube:
	@bash scripts/setup_minikube.sh

install_splunk:
	@bash scripts/install_splunk.sh

deploy_sck_otel_collector:
	@bash scripts/deploy_sck_otel_collector.sh

deploy_log_generator:
	@bash scripts/deploy_log_generator.sh

setup_python:
	@bash scripts/setup_python.sh

run_functional_tests:
	@bash scripts/run_functional_tests.sh

##@ Tests
.PHONY: e2e
e2e: ## Run end-to-tests
	$(KUTTL) test
.PHONY: prepare-e2e
prepare-e2e: set-test-image-vars set-image-controller docker-build start-kind ## prepare end-to-end tests
	mkdir -p tests/_build/crds tests/_build/manifests
	$(KUSTOMIZE) build config/default -o tests/_build/manifests/01-splunk-otel-operator.yaml
	$(KUSTOMIZE) build config/crd -o tests/_build/crds/

.PHONY: clean-e2e
clean-e2e: ## delete kind cluster
	kind delete cluster

.PHONY: start-kind
start-kind:
	if kind get clusters | grep kind; then \
		echo "kind cluster has already been created"; \
	else \
		kind create cluster --config $(KIND_CONFIG); \
	fi

	kind load docker-image local/splunk-otel-operator:e2e
