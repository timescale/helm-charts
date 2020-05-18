ROGUE_KUSTOMIZE_FILES := $(shell find charts/timescaledb-single/kustomize/ -mindepth 2 -type f ! -path '*kustomize/example*')
ROGUE_KUSTOMIZE_DIRS := $(shell find charts/timescaledb-single/kustomize/  -mindepth 1 -type d ! -path '*kustomize/example*')

.PHONY: publish
publish: publish-multinode publish-single

.PHONY: publish-multinode
publish-multinode:
	helm package charts/timescaledb-multinode --destination charts/repo
	helm repo index charts/repo

.PHONY: publish-single
publish-single:
	@if [ "$(ROGUE_KUSTOMIZE_FILES)" != "" ]; then \
		echo "Found non-example files in the timescaledb-single/kustomize directory"; \
		echo "Please remove these files using 'make clean' or manually"; \
		echo ""; \
		echo "Unfortunately we cannot exclude these files in .helmignore due to"; \
		echo "        https://github.com/helm/helm/issues/3622"; \
		echo ""; \
		exit 1; \
	fi
	helm package charts/timescaledb-single --destination charts/repo
	helm repo index charts/repo

.PHONY: clean
clean:
	@if [ "$(ROGUE_KUSTOMIZE_FILES)" != "" ]; then rm -v $(ROGUE_KUSTOMIZE_FILES); fi
	@if [ "$(ROGUE_KUSTOMIZE_DIRS)" != "" ]; then rmdir -v $(ROGUE_KUSTOMIZE_DIRS); fi
