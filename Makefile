.PHONY: publish-multinode
publish-multinode:
	helm package charts/timescaledb-multinode --destination charts/repo
	helm repo index charts/repo

.PHONY: publish-single
publish-single:
	helm package charts/timescaledb-single --destination charts/repo
	helm repo index charts/repo

.PHONY: publish
publish: publish-multinode publish-single

.PHONY: lint
lint:
	@helm lint charts/timescaledb

FILES_TO_VERIFY := $(shell ls charts/timescaledb/values/*.yaml charts/timescaledb/values.yaml)
.PHONY: verify-schema
verify-schema: lint
	@for file in $(FILES_TO_VERIFY); do \
		echo verifying file $$file ; \
		helm template charts/timescaledb -f $$file || exit 1; \
 	done;

