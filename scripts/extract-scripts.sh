#!/bin/bash

# Set this after CI detection to prevent "unbound variable" error
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

TMP_DIR=tmp

SINGLE_VALUES_FILES="charts/timescaledb-single/values.yaml $(ls charts/timescaledb-single/ci/*.yaml)"

for vfile in $SINGLE_VALUES_FILES; do \
	scripts_dir="${TMP_DIR}/$(basename "${vfile}")"
    mkdir -p "${scripts_dir}"; \
	helm template charts/timescaledb-single -s templates/configmap-scripts.yaml -f "${vfile}" | gojsontoyaml -yamltojson > "${scripts_dir}/temp.json"
	for script in $(jq '.data | keys | sort | .[]' -r "${scripts_dir}/temp.json"); do
		echo "Extracting script: ${vfile} / ${script}"
		jq -r --arg script "${script}" '.data[$script]' "${scripts_dir}/temp.json" > "${scripts_dir}/${script}"
	done
done
