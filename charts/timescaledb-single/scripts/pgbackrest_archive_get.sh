#!/bin/sh

: "${ENV_FILE:=${HOME}/.pgbackrest_environment}"
if [ -f "${ENV_FILE}" ]; then
echo "Sourcing ${ENV_FILE}"
. "${ENV_FILE}"
fi


# PGBACKREST_BACKUP_ENABLED variable is passed in StatefulSet template
[ "${PGBACKREST_BACKUP_ENABLED}" = "true" ] || exit 1

exec pgbackrest --stanza=poddb archive-get "${1}" "${2}"
