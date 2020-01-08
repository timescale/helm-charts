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