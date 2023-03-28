#!/bin/sh

# If no backup is configured, archive_command would normally fail. A failing archive_command on a cluster
# is going to cause WAL to be kept around forever, meaning we'll fill up Volumes we have quite quickly.
#
# Therefore, if the backup is disabled, we always return exitcode 0 when archiving

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - archive - $1"
}

[ -z "$1" ] && log "Usage: $0 <WALFILE or DIRECTORY>" && exit 1

: "${ENV_FILE:=${HOME}/.pgbackrest_environment}"
if [ -f "${ENV_FILE}" ]; then
    echo "Sourcing ${ENV_FILE}"
    . "${ENV_FILE}"
fi


# PGBACKREST_BACKUP_ENABLED variable is passed in StatefulSet template
[ "${PGBACKREST_BACKUP_ENABLED}" = "true" ] || exit 0

exec pgbackrest --stanza=poddb archive-push "$@"
