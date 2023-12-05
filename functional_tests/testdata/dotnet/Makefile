# Default image repository
TODO: Set this to quay
IMAGE_REPO ?= jvsplk/dotnet_test
#IMAGE_REPO ?= quay.io/splunko11ytest/dotnet_test

.PHONY: push
push:
	docker buildx build --file Dockerfile --platform linux/amd64,linux/arm64 --no-cache	 --tag $(IMAGE_REPO):latest --push .
