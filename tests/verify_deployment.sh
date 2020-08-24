#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 VALUES_FILE [DEPLOYMENT_NAME]"
fi

SCRIPTDIR="$(dirname "$0")"
SINGLE_CHART_DIR=${SINGLE_CHART_DIR:-./charts/timescaledb-single}
TEST_REPLICA=${TEST_REPLICA:-1}
PULL_TIMEOUT=${PULL_TIMEOUT:-600s}
DEPLOYMENT_TIMEOUT=${DEPLOYMENT_TIMEOUT:-180s}
DELETE_DEPLOYMENT=${DELETE_DEPLOYMENT:-1}

deployment_name() {
    basename "${1%".yaml"}" | tr '.' '-' | tr '_' '-' | cut -c 1-30
}

undeploy() {
    if [ "${DELETE_DEPLOYMENT}" -eq 1 ]; then
        helm delete "$1"
    fi
}

deploy() {
    helm upgrade --install "$1" "${SINGLE_CHART_DIR}" -f "$2" -f "${SCRIPTDIR}/values.yaml" > /dev/null || exit 1
}

wait_for_docker() {
    ## We will wait for the first pod to be initialized; we do this, as on a pristine cluster
    ## most of the time may be spent pulling a Docker Image.
    echo "Waiting for first Pod to be initialized (docker pull completed)"
    if ! kubectl wait --timeout="${PULL_TIMEOUT}" --for=condition=initialized "pod/${1}-timescaledb-0"; then
        echo "Timed out waiting for docker image pull"
        undeploy "${DEPLOYMENT}"
        exit 1
    fi
}

test_deploy() {
    DEPLOYMENT="$1"
    ## By using a Job instead of relying on tools on the system that is running the tests, we verify at least
    ## the following:
    ##  * There is a primary running
    ##  * There is a primary service pointing to the primary
    ##  * There is a replica running
    ##  * There is a replica service pointing to the replica(s)
    ##  * The password set is valid for both the primary and the replica
    ##  * Inserting data works on the primary
    ##  * TimescaleDB is installed and can create hypertables
    ##  * Changes made on the primary propagate to (at least one) replica
    JOBNAME="${DEPLOYMENT}"
    kubectl delete "job/${JOBNAME}" > /dev/null 2>&1
    ## Poor man's kustomize, for now, this seems adequate for its purposes though
    sed "s/example\$/${DEPLOYMENT}/g; s/TEST_REPLICA, value: \".*\"/TEST_REPLICA, value: \"${TEST_REPLICA}\"/g" "${SCRIPTDIR}/wait_for_example_job.yaml" \
      | kubectl apply -f -

    echo "Waiting for deployment \"${JOBNAME}\" to complete ..."
    if ! kubectl wait --timeout="${DEPLOYMENT_TIMEOUT}" --for=condition=complete "job/${JOBNAME}"; then
        echo "===================================================="
        echo " ERROR: deployment ${DEPLOYMENT}, details:"
        echo "===================================================="
        kubectl get pod,ep,configmap,service -l app="${DEPLOYMENT}-timescaledb"
        echo "...................................................."
        kubectl describe "pod/${DEPLOYMENT}-timescaledb-0"
        kubectl logs "pod/${DEPLOYMENT}-timescaledb-0" -c timescaledb
        echo "...................................................."
        kubectl describe "pod/${DEPLOYMENT}-timescaledb-1"
        kubectl logs "pod/${DEPLOYMENT}-timescaledb-1" -c timescaledb
        echo "...................................................."
        kubectl logs "job/${JOBNAME}"
        echo "===================================================="
        undeploy "${DEPLOYMENT}"
        exit 1
    fi
    echo "===================================================="
    echo " OK: deployment ${DEPLOYMENT}"
    echo "===================================================="
}


VALUES_FILE="$1"
shift
if [ -z "$1" ]; then
    DEPLOYMENT="$(basename "${VALUES_FILE%".yaml"}" | tr '.' '-' | tr '_' '-')"
else
    DEPLOYMENT="$1"
fi

terminate() {
    echo "Terminating verification of deployment ${DEPLOYMENT}"
    exit 1
}
trap terminate TERM QUIT

deploy "${DEPLOYMENT}" "${VALUES_FILE}"
wait_for_docker "${DEPLOYMENT}"
test_deploy "${DEPLOYMENT}"
undeploy "${DEPLOYMENT}"
