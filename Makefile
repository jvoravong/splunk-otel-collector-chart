##@ General
# The general settings and variables for the project
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

OVERRIDE_OS_CHECK ?= false
.PHONY: install-tools
install-tools: $(LOCALBIN) ## Install tools (macOS/Linux)
	@OVERRIDE_OS_CHECK=$(OVERRIDE_OS_CHECK) LOCALBIN=$(LOCALBIN) ./ci_scripts/install-tools.sh || exit 1

##@ Build
# Tasks related to building the Helm chart

.PHONY: repo-update
repo-update: ## Update Helm repositories to latest
	@{ \
	if ! (helm repo list | grep -q open-telemetry) ; then \
		helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts || exit 1; \
	fi ;\
	if ! (helm repo list | grep -q jetstack) ; then \
		helm repo add jetstack https://charts.jetstack.io || exit 1; \
	fi ;\
	helm repo update open-telemetry jetstack || exit 1; \
	}

.PHONY: dep-build
dep-build: ## Build the Helm chart with latest dependencies from the current Helm repositories
	@{ \
	DEP_OK=true ;\
	DIR=helm-charts/splunk-otel-collector ;\
	if ! helm dependencies list $$DIR | grep open-telemetry | grep -q ok ; then DEP_OK=false ; fi ;\
	if ! helm dependencies list $$DIR | grep jetstack | grep -q ok ; then DEP_OK=false ; fi ;\
	if [ "$$DEP_OK" = "false" ] ; then helm dependencies build $$DIR || exit 1; fi ;\
	}

.PHONY: render
render: repo-update dep-build ## Render the Helm chart with the examples as input
	bash ./examples/render-examples.sh || exit 1

##@ Test
# Tasks related to testing the Helm chart

.PHONY: lint
lint: ## Lint the Helm chart with ct
	@echo "Linting Helm chart..."
	ct lint --config=ct.yaml || exit 1

.PHONY: pre-commit
pre-commit: ## Test the Helm chart with pre-commit
	@echo "Checking the Helm chart with pre-commit..."
	pre-commit run --all-files || exit 1

##@ Changelog
# Tasks related to changelog management
CHLOGGEN_NEW_SCRIPT := ./ci_scripts/chloggen-new.sh

.PHONY: chlog-available
chlog-available: ## Validate the chloggen tool is available
	@if [ -z "$(CHLOGGEN)" ]; then \
		echo "Error: chloggen is not available. Please run 'make install-tools' to install it."; \
		exit 1; \
	fi

.PHONY: chlog-new
chlog-new: chlog-available ## Creates or updates a YAML file under .chloggen
	# Example Usage:
	#   make chlog-new
	#   make chlog-new CHANGE_TYPE=enhancement COMPONENT=agent NOTE="Add feature X" ISSUES='["4242"]' FILENAME=add-feature-x SUBTEXT="Supports Y"
	@$(CHLOGGEN_NEW_SCRIPT) || exit 1

.PHONY: chlog-validate
chlog-validate: chlog-available ## Validates all YAML files in .chloggen
	$(CHLOGGEN) validate || exit 1

.PHONY: chlog-preview
chlog-preview: chlog-available ## Provide a preview of the generated CHANGELOG.md file for a release
	$(CHLOGGEN) update --dry || exit 1

.PHONY: chlog-update
chlog-update: chlog-available ## Creates a release CHANGELOG.md entry from content in .chloggen
	@if [[ ! "$(VERSION)" =~ ^[0-9]+\.[0-9]+\.[0-9]+$$ ]]; then \
		echo "Error: Invalid version. Try running something like 'make chlog-update VERSION=0.85.0'"; \
		exit 1; \
	fi
	@FORMATTED_VERSION="[$(VERSION)] - $$(date +'%Y-%m-%d')"; \
	$(CHLOGGEN) update --version $$FORMATTED_VERSION || exit 1
	@./ci_scripts/update_changelog_links.sh || exit 1
