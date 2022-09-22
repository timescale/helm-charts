SHELL=/bin/bash -euo pipefail

KUBE_VERSION ?= 1.23
KIND_CONFIG ?= ./testdata/kind-$(KUBE_VERSION).yaml

TMP_DIR=tmp

.PHONY: json-schema
json-schema: charts/timescaledb-single/values.schema.json

charts/timescaledb-single/values.schema.json:
	find charts/ -name values.schema.yaml -printf 'cat %p | gojsontoyaml -yamltojson | jq -r > $$(dirname %p)/values.schema.json' | sh

.PHONY: lint
lint:  ## Lint helm chart using ct (chart-testing).
	ct lint --config ct.yaml

.PHONY: clean
clean:
	rm -rf $(TMP_DIR)

$(TMP_DIR):
	mkdir -p $(TMP_DIR)

.PHONY: extract-scripts
extract-scripts: $(TMP_DIR)  ## Extract shell scripts from helm templates
	./scripts/extract-scripts.sh

.PHONY: shellcheck
shellcheck: extract-scripts
	for f in $$(find scripts/ -name "*.sh" -type f) $$(find $(TMP_DIR)/ -name "*.sh" -type f); do \
		shellcheck $$f --exclude=SC1090,SC1091,SC2148 ;\
	done

.PHONY: promscale-mixin
promscale-mixin:
	./scripts/generate-promscale-alerts.sh

.PHONY: delete-kind
delete-kind:  ## This is a phony target that is used to delete the local kubernetes kind cluster.
	kind delete cluster && sleep 10

.PHONY: start-kind
start-kind: delete-kind  ## This is a phony target that is used to create a local kubernetes kind cluster.
	kind create cluster --config $(KIND_CONFIG)
	kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s

.PHONY: load-images
load-images:  ## Load images into the local kubernetes kind cluster.
	./scripts/load-images.sh

.PHONY: install-db
install-db:  ## Install the testing database into the local kubernetes kind cluster.
	helm install \
		--namespace ext-db \
		--create-namespace db \
		--wait \
		--timeout 15m \
		--debug \
		charts/timescaledb-single \
		--set replicaCount=1 \
		--set secrets.credentials.PATRONI_SUPERUSER_PASSWORD="temporarypassword" \
		--set loadBalancer.enabled=false

.PHONY: e2e
e2e: load-images  ## Run e2e installation tests using ct (chart-testing).
	ct install --config ct.yaml --exclude-deprecated

### TODO(paulfantom): remove this section once timescaledb-single is using `ct` and `helm test` for testing.

SINGLE_CHART_DIR := charts/timescaledb-single
SINGLE_VALUES_FILES := $(SINGLE_CHART_DIR)/values.yaml $(wildcard $(SINGLE_CHART_DIR)/values/*.yaml)
DEPLOYMENTS := $(SINGLE_VALUES_FILES)
K8S_NAMESPACE ?= citest

# We test sequentially, as in GitHub actions we do not have a lot of CPU available,
# so scheduling the pods concurrently does not work
.PHONY: test
test: prepare-ci
	for f in $(SINGLE_VALUES_FILES); do \
		./tests/verify_deployment.sh $${f}; \
	done

.PHONY: prepare-ci
prepare-ci:
	@kubectl create namespace $(K8S_NAMESPACE) || true
	@kubectl config set-context --current --namespace $(K8S_NAMESPACE)
	@kubectl apply -f tests/custom_pgbouncer_user_list.yaml
	@kubectl apply -f tests/custom-init-scripts.yaml
	@kubectl apply -f tests/custom_secrets.yaml
	@for storageclass in gp2 slow; do \
		kubectl get storageclass/$${storageclass} > /dev/null 2> /dev/null || \
		kubectl get storageclass -o json \
			| jq '[.items[] | select(.metadata.annotations."storageclass.kubernetes.io/is-default-class"=="true")] | .[0]' \
			| jq ". | del(.metadata.annotations.\"storageclass.kubernetes.io/is-default-class\") | .metadata.name=\"$${storageclass}\"" \
			| kubectl create -f - ; \
	done ; \
	exit 0

### END_OF_SECTION
