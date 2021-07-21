#!/usr/bin/env bash
set -e

USAGE="$(basename $0) <environment> <region> [namespace]"

dependencies() {
  helm dependency list | grep -q 'missing\|wrong version\|too many matches' && {
    helm dependency update || exit 1
  }
  return 0
}

# validate helm v3 is installed
type helm &>/dev/null || {
  echo "couldn't find 'helm' command in the path, make sure it's installed" >&2
  exit 1
}
helm version | cut -d '"' -f 2 | grep -q v3 || {
  echo "helm V3 is required" >&2
  exit 1
}

# at least 2 args must be passed
[ $# -lt 2 ] && {
  echo $USAGE >&2
  exit 1
}

# change to script directory
cd ${0%/*}
NAME=`basename $PWD`
ENV="$1"
REGION="$2"
NS="${3:-monitoring}"
REGIONAL_VALUES="values/$REGION.yaml"
ENV_VALUES="values/$ENV.yaml"
VALUES="values/$ENV/$REGION.yaml"

test -f "$REGIONAL_VALUES" && {
  echo "regional values file $REGIONAL_VALUES will be used"
} || REGIONAL_VALUES=/dev/null

test -f "$ENV_VALUES" && {
  echo "env values file $ENV_VALUES will be used"
} || ENV_VALUES=/dev/null

test -f "$VALUES" && {
  echo "values file $VALUES will be used"
} || VALUES=/dev/null

# validate chart dependencies
dependencies

helm upgrade --install timescaledb \
  --reset-values --dry-run\
  --history-max 3 \
  --kube-context teleport.$REGION.$ENV.firebolt.io \
  --namespace $NS --create-namespace \
  --values $REGIONAL_VALUES \
  --values $ENV_VALUES \
  --values $VALUES .
