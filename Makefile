# Renders the Helm templates for all use case scenarios in ./examples
.PHONY: render
render: repo-update dep-build
	bash ./examples/render-examples.sh

# Ensures the required Helm repositories are available
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

# Ensures the Helm chart dependencies are current and built
.PHONY: dep-build
dep-build:
	@{ \
  OK=true ;\
  DIR=helm-charts/splunk-otel-collector ;\
	if ! helm dependencies list $$DIR | grep open-telemetry | grep -q ok ; then OK=false ; fi ;\
	if ! helm dependencies list $$DIR | grep jetstack | grep -q ok ; then OK=false ; fi ;\
	if ! $$OK ; then helm dependencies build $$DIR ; fi ;\
	}

# Updates the CHANGELOG.md for a new release
.PHONY: changelog-release
changelog-release:
	@{ \
	VERSION=$$(yq eval '.version' helm-charts/splunk-otel-collector/Chart.yaml) ;\
	DATE=$$(date +%Y-%m-%d) ;\
	if [ $$(uname) = "Darwin" ]; then \
		sed -i '' "s/## Unreleased/## Unreleased\n\n## [v$$VERSION] - $$DATE/g" CHANGELOG.md ;\
	else \
		sed -i "s/## Unreleased/## Unreleased\n\n## [v$$VERSION] - $$DATE/g" CHANGELOG.md ;\
	fi \
	}
