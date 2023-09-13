##@ General
# The general settings and variables for the project
# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

CHLOGGEN ?= $(LOCALBIN)/chloggen
SHELL := /bin/bash

# The help target as provided
.PHONY: help
help: ## Display Makefile help information for all actions
	@awk 'BEGIN {FS = ":.*##"; \
                 printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
          /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
          /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' \
          $(MAKEFILE_LIST)

##@ Initialization
# Tasks for setting up the project environment

.PHONY: init
init: install-tools ## Initialize the environment
	# TODO: Add more execution steps here
	@echo "Initialization complete."

# install-tools: Set up dev environment
# Installs/Upgrades dev tools via Homebrew. Supports macOS/Linux. Also installs chloggen.
# Use OVERRIDE_OS_CHECK=true to skip OS check.
OVERRIDE_OS_CHECK ?= false
.PHONY: install-tools
install-tools: ## Install tools (macOS/Linux)
	@OVERRIDE_OS_CHECK=$(OVERRIDE_OS_CHECK) LOCALBIN=$(LOCALBIN) ./ci_scripts/install-tools.sh

##@ Build
# Tasks related to building the Helm chart

.PHONY: repo-update
repo-update: ## Update Helm repositories to latest
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
dep-build: ## Build the Helm chart with latest dependencies from the current Helm repositories
	@{ \
  OK=true ;\
  DIR=helm-charts/splunk-otel-collector ;\
	if ! helm dependencies list $$DIR | grep open-telemetry | grep -q ok ; then OK=false ; fi ;\
	if ! helm dependencies list $$DIR | grep jetstack | grep -q ok ; then OK=false ; fi ;\
	if ! $$OK ; then helm dependencies build $$DIR ; fi ;\
	}

.PHONY: render
render: repo-update dep-build ## Render the Helm chart with the examples as input
	bash ./examples/render-examples.sh

##@ Test
# Tasks related to building the Helm chart

.PHONY: lint
lint: ## Lint the Helm chart with ct
	@echo "Linting Helm chart..."
	ct lint --config=ct.yaml

.PHONY: pre-commit
pre-commit: ## Test the Helm chart with pre-commit
	@echo "Checking the Helm chart with pre-commit..."
	pre-commit

##@ Changelog
# Tasks related to changelog management
# See: https://github.com/open-telemetry/opentelemetry-go-build-tools/tree/main/chloggen

FILENAME?=$(shell git branch --show-current)
.PHONY: chlog-available
chlog-available: ## Validate the chloggen tool is available
	@if [ -z "$(CHLOGGEN)" ]; then \
		echo "Error: chloggen is not available. Please run 'make install-tools' to install it."; \
		exit 1; \
	fi

.PHONY: chlog-new
chlog-new: chlog-available ## Creates a new YAML file under .chloggen to later be inserted into CHANGELOG.md for the next release
	$(CHLOGGEN) new --filename $(FILENAME)
	echo "Make sure to update the contents of ${FILENAME} with information about your changes."

.PHONY: chlog-validate
chlog-validate: chlog-available ## Validates all YAML files in .chloggen
	$(CHLOGGEN) validate

.PHONY: chlog-preview
chlog-preview: chlog-available ## Provide a preview of the generated CHANGELOG.md file for a release
	$(CHLOGGEN) update --dry

.PHONY: chlog-update
chlog-update: chlog-available ## Updates the CHANGELOG.md file for a release. Example: make chlog-update VERSION=1.2.3
	# Validate the version format
	@if [[ ! "$(VERSION)" =~ ^[0-9]+\.[0-9]+\.[0-9]+$$ ]]; then \
		echo "Error: Invalid version format. Tip: Use the format X.Y.Z (e.g., 1.123.23)."; \
		exit 1; \
	fi
	# Convert the version to the desired format
	@FORMATTED_VERSION="[$(VERSION)] - $$(date +'%Y-%m-%d')"; \
	$(CHLOGGEN) update --version $$FORMATTED_VERSION


