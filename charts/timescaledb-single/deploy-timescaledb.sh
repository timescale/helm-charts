#!/usr/bin/env bash

# This script may be used to deploy our timescaledb Kubernetes pod.

set -o pipefail

readonly progname="$(basename $0)"

usage() {
    cat <<EOF
Usage: $progname [OPTIONS] NAMESPACE

This script may be used to deploy our timescaledb Kubernetes pod.

Options:
  -h    Show this message and exit.
EOF

    exit 1
}

deploy_timescaledb() {
    local ns="$1"

    [[ -n $ns ]] || { echo "$progname: missing namespace argument!"; exit 1; }

    helm upgrade timescaledb . --values values.yaml --install --create-namespace --namespace=$ns --wait --timeout 8000s --debug
}

sanity_checks() {
    [[ -f values.yaml ]] || { echo "$progname: no values.yaml file in current directory: $(pwd)"; exit 1; }

    return 0
}

# --- main() ---

while getopts "h" opt ; do
    case $opt in
        h) usage ;;
        *) usage ;;
    esac
done

shift $((OPTIND - 1))

[[ $# == 1 ]] || { echo "$progname: missing or too many positional arguments!"; exit 1; }

namespace="$1"

sanity_checks
deploy_timescaledb $namespace

exit 0
