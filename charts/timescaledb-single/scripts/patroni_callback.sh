#!/bin/sh
set -e

: "${ENV_FILE:=${HOME}/.pod_environment}"
if [ -f "${ENV_FILE}" ]; then
    echo "Sourcing ${ENV_FILE}"
    . "${ENV_FILE}"
fi

for suffix in "$1" all
do
    CALLBACK="/etc/timescaledb/callbacks/${suffix}"
    if [ -f "${CALLBACK}" ]
    then
    "${CALLBACK}" "$@"
    fi
done
