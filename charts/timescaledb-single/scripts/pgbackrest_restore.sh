#!/bin/sh

: "${ENV_FILE:=${HOME}/.pod_environment}"
if [ -f "${ENV_FILE}" ]; then
echo "Sourcing ${ENV_FILE}"
. "${ENV_FILE}"
fi

# PGBACKREST_BACKUP_ENABLED variable is passed in StatefulSet template
[ "${PGBACKREST_BACKUP_ENABLED}" = "true" ] || exit 1

# PGDATA and WALDIR are set in the StatefulSet template and are sourced from the ENV_FILE
# PGDATA=
# WALDIR=

# A missing PGDATA points to Patroni removing a botched PGDATA, or manual
# intervention. In this scenario, we need to recreate the DATA and WALDIRs
# to keep pgBackRest happy
uid="$(id -u)"; gid="$(id -g)"
[ -d "${PGDATA}" ] || install -o "$uid" -g "$gid" -d -m 0700 "${PGDATA}"
[ -d "${WALDIR}" ] || install -o "$uid" -g "$gid" -d -m 0700 "${WALDIR}"

exec pgbackrest --force --delta --log-level-console=detail restore
