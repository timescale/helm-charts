ROGUE_KUSTOMIZE_FILES := $(shell find charts/timescaledb-single/kustomize/ -mindepth 2 -type f ! -path '*kustomize/example*')
ROGUE_KUSTOMIZE_DIRS := $(shell find charts/timescaledb-single/kustomize/  -mindepth 1 -type d ! -path '*kustomize/example*')
SINGLE_CHART_DIR := charts/timescaledb-single
MULTI_CHART_DIR := charts/timescaledb-multinode
CI_SINGLE_DIR := $(SINGLE_CHART_DIR)/ci/
SINGLE_VALUES_FILES := $(SINGLE_CHART_DIR)/values.yaml $(wildcard $(SINGLE_CHART_DIR)/values/*.yaml)
DEPLOYMENTS := $(SINGLE_VALUES_FILES)
K8S_NAMESPACE ?= citest

export PULL_TIMEOUT ?= 3000s
export DEPLOYMENT_TIMEOUT ?= 600s

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
clean: clean-ci
	@if [ "$(ROGUE_KUSTOMIZE_FILES)" != "" ]; then rm -v $(ROGUE_KUSTOMIZE_FILES); fi
	@if [ "$(ROGUE_KUSTOMIZE_DIRS)" != "" ]; then rmdir -v $(ROGUE_KUSTOMIZE_DIRS); fi

.PHONY: assert-schema-equals
assert-schema-equals:
	@cat $(SINGLE_CHART_DIR)/values.schema.yaml | python3 ./yaml2json.py | jq '.[0]' | git --no-pager diff --no-index - $(SINGLE_CHART_DIR)/values.schema.json

.PHONY: json-schema
json-schema:
	cat $(SINGLE_CHART_DIR)/values.schema.yaml | python3 ./yaml2json.py | jq '.[0]' > $(SINGLE_CHART_DIR)/values.schema.json

.PHONY: lint
lint: assert-schema-equals
	@for file in $(SINGLE_VALUES_FILES); do \
		echo "Linting timescaledb-single using file: $$file" ; \
		helm lint $(SINGLE_CHART_DIR) -f "$$file" --set backup.enabled=true --set pgBouncer.enabled=true --set prometheus.enabled=true --set unsafe=true || exit 1 ; \
	done
	@helm lint $(MULTI_CHART_DIR)

# We're not symlinking the files, as that generates *a ton* of Helm noise
.PHONY: refresh-ci-values
refresh-ci-values: clean-ci
	@mkdir -p ./$(CI_SINGLE_DIR)/
	@for file in $(SINGLE_VALUES_FILES); do \
		cp "$$file" "$(CI_SINGLE_DIR)/$$(basename $$file)-values.yaml"; \
	done

.PHONY: clean-ci
clean-ci:
	@rm -rf ./$(CI_SINGLE_DIR)
	@mkdir -p ./$(CI_SINGLE_DIR)/
	@kubectl delete namespace $(K8S_NAMESPACE) 2>/dev/null || true

.PHONY: shellcheck shellcheck-single
shellcheck: shellcheck-single
shellcheck-single:
	@for vfile in $(SINGLE_VALUES_FILES); do \
		helm template $(SINGLE_CHART_DIR) -s templates/configmap-scripts.yaml -f $$vfile > $(CI_SINGLE_DIR)/temp.yaml || exit 1 ; \
		cat $(CI_SINGLE_DIR)/temp.yaml | python3 ./yaml2json.py > $(CI_SINGLE_DIR)/temp.json || exit 1; \
		for script in $$(jq '.[0].data | keys | sort | .[] | select(endswith(".sh"))' -r $(CI_SINGLE_DIR)/temp.json); do \
			echo "shellcheck - $$script (from values file $$vfile)" ; \
			jq ".[0].data.\"$${script}\"" -r $(CI_SINGLE_DIR)/temp.json | shellcheck - --exclude=SC1090 || exit 1; \
		done ; \
		rm $(CI_SINGLE_DIR)/temp.* ; \
	done

.PHONY: install-example
install-example: prepare-ci
	DELETE_DEPLOYMENT=0 TEST_REPLICA=0 ./tests/verify_deployment.sh $(SINGLE_CHART_DIR)/values.yaml example

.PHONY: smoketest
smoketest: prepare-ci
	./tests/verify_deployment.sh $(SINGLE_CHART_DIR)/values.yaml smoketest

# We test sequentially, as in GitHub actions we do not have a lot of CPU available,
# so scheduling the pods concurrently does not work
.PHONY: test
test: prepare-ci
	for f in $(SINGLE_VALUES_FILES); do \
		./tests/verify_deployment.sh $${f} || exit 1; \
	done

.PHONY: prepare-ci
prepare-ci:
	@kubectl create namespace $(K8S_NAMESPACE) || true
	@kubectl config set-context --current --namespace $(K8S_NAMESPACE)
	@kubectl apply -f tests/custom_pgbouncer_user_list.yaml
	@kubectl apply -f tests/custom-init-scripts.yaml
	@kubectl kustomize "$(SINGLE_CHART_DIR)/kustomize/example" | kubectl apply --namespace $(K8S_NAMESPACE) -f -
	@for storageclass in gp2 slow; do \
		kubectl get storageclass/$${storageclass} > /dev/null 2> /dev/null || \
		kubectl get storageclass -o json \
			| jq '[.items[] | select(.metadata.annotations."storageclass.kubernetes.io/is-default-class"=="true")] | .[0]' \
			| jq ". | del(.metadata.annotations.\"storageclass.kubernetes.io/is-default-class\") | .metadata.name=\"$${storageclass}\"" \
			| kubectl create -f - ; \
	done ; \
	exit 0
