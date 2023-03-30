.PHONY: docs
docs:
	helm-docs -s file -u -o values.md -t .values.gotmpl

.PHONY: render
render:
	bash ./examples/render-examples.sh
