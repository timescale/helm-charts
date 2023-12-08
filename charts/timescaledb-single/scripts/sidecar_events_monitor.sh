#!/bin/bash
#
# Monitor Kubernetes events related to this pod (determined via HOSTNAME env var),
# in order to determine when some target container of this pod has stopped according
# to Kubernetes.

# Get the pod service account token.
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# Set the Kubernetes API server address.
API_SERVER="https://kubernetes.default.svc"
# Get the pod name.
POD_NAME=$HOSTNAME
# Construct the authorization header
AUTH_HEADER="Authorization: Bearer $TOKEN"
# Last seen event timestamp (for paging).
LAST_EVENT_TIME="$(date +'%Y-%m-%dT%H:%M:%SZ')"
# The namespace in which this pod is running.
TARGET_NS="${1}"
# The container for which events are being monitored, in order to
# determine when the target container has stopped according to Kubernetes.
TARGET_CONTAINER="${2}"

function process_events() {
    while true; do
        # Construct the URL with paging parameters.
        URL="$API_SERVER/api/v1/namespaces/savannah-system/events?fieldSelector=involvedObject.name=$POD_NAME&limit=500&since=$LAST_EVENT_TIME"

        # Fetch a batch of events for the current pod.
        EVENTS=$(curl -s -k -H "$AUTH_HEADER" "$URL")

        # Check for "ContainerStopped" event related to the "timescaledb" container.
        if [[ $(echo "$EVENTS" | jq -r '.items[] | select(.reason == "ContainerStopped" and .involvedObject.name == "timescaledb")') ]]; then
            echo "timescaledb container in pod $POD_NAME has stopped, will call linkerd-shutdown now"
        fi

        # Extract timestamp of the latest event for next iteration.
        LAST_EVENT_TIME=$(echo "$EVENTS" | jq -r '.items[0].lastTimestamp')

        # Sleep for a short interval before checking again.
        sleep 5
    done

    # Execute custom cleanup routine.
    custom_cleanup
}

function custom_cleanup() {
    echo "executing custom cleanup routine: shutting down local linkerd-proxy"
    curl -s -m 5 -X POST http://localhost:4191/shutdown
}

function main() {
    # This trap ensures that this container will not shutdown based on SIGTERM.
    # It will do its absolute damnedest to detect when the target container is shutdown first
    # in order to ensure that it can execute its custom shutdown logic.
    trap process_events SIGTERM
    if [[ $TARGET_NS == "" || $TARGET_CONTAINER == "" ]]; then
        echo "missing input, can not proceed"
        echo "usage: $0 <namespace> <pod>"
        exit 1
    fi
    process_events
}

# Execute main if this script is being executed, not sourced.
#
# Though this script should never be sourced, we employ some defensive programming here.
if [ "${BASH_SOURCE[0]}" == "$0" ]; then main "$@"; fi
