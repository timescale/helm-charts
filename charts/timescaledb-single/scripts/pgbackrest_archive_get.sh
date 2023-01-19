#!/bin/sh
# PGBACKREST_BACKUP_ENABLED variable is passed in StatefulSet template
[ "${PGBACKREST_BACKUP_ENABLED}" = "true" ] || exit 1

: "${ENV_FILE:=${HOME}/.pgbackrest_environment}"
if [ -f "${ENV_FILE}" ]; then
echo "Sourcing ${ENV_FILE}"
. "${ENV_FILE}"
fi

exec pgbackrest --stanza=poddb archive-get "${1}" "${2}"
