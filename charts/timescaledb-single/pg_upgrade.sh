#!/bin/bash

set -e

function log {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - pg_upgrade - $1"
}

if [ -z $2 ]
then
    cat <<__EOT__
Usage: $0 OLD NEW

Example:
$0 11 12
__EOT__
    exit 1
fi

OLDVERSION="$1"
shift
NEWVERSION="$1"
shift

export PGDATANEW=/var/lib/postgresql/data.new
export PGDATAOLD=/var/lib/postgresql/data
export PGBINOLD=/usr/lib/postgresql/${OLDVERSION}/bin
export PGBINNEW=/usr/lib/postgresql/${NEWVERSION}/bin
export WALDIRNEW=/var/lib/postgresql/wal/pg_wal.new
export WALDIROLD=/var/lib/postgresql/wal/pg_wal

log "We're going to upgrade PostgreSQL from ${OLDVERSION} to ${NEWVERSION}"

STARTED="$(log "started")"

function finish {
  rm -rf /var/lib/postgresql/data.new || true
  rm -rf /var/lib/postgresql/wal/pg_wal.new || true

  # We should stop the running instance if they're running
  if [ -f "${PGDATAOLD}/postmaster.pid" ]
  then
    if grep -q ${NEWVERSION} "${PGDATAOLD}"/PG_VERSION
    then
        "${PGBINNEW}/pg_ctl" -D "${PGDATAOLD}" stop
    else
        "${PGBINOLD}/pg_ctl" -D "${PGDATAOLD}" stop
    fi
  fi
}

trap finish SIGINT SIGTERM EXIT

function update_timescaledb {
    for db in $(psql -AtXq -c "SELECT quote_ident(datname) FROM pg_database WHERE datallowconn")
    do
        psql -tX -f - --set DB="$db" <<__SQL__
\c :DB
SET timescaledb.disable_load to true;

-- https://github.com/timescale/timescaledb/issues/1878
ALTER DATABASE :DB reset timescaledb.restoring;

SELECT
    CASE
        WHEN extversion IS NULL then false
        ELSE extversion != default_version
    END AS should_upgrade
FROM
    pg_available_extensions
LEFT JOIN
    pg_extension ON (name=extname)
WHERE
    name='timescaledb'
\gset

\if :should_upgrade
SELECT format('Updating timescaledb extension for database %I', current_catalog);
ALTER EXTENSION timescaledb UPDATE;
\endif
\quit
__SQL__
    done
}

log "Setting sane permissions on all involved directories"
install -o postgres -g postgres -d -m 0700  "${PGDATAOLD}" "${PGDATANEW}" "${WALDIROLD}" "${WALDIRNEW}"

log "Starting PostgreSQL using old binaries"
"${PGBINOLD}/pg_ctl" -D "${PGDATAOLD}" start -l logfile
while ! pg_isready -U postgres; do sleep 1; done;

# We need to ensure that the timescaledb extension is upgraded first, as both the old
# and the new database should have the same timescaledb version
log "Updating timescaledb extension in the current databases"
update_timescaledb

log "Timescaledb Extension updated"

log "Stopping PostgreSQL using old binaries"
"${PGBINOLD}/pg_ctl" -D "${PGDATAOLD}" stop

log "Creating a new (empty) cluster using the new binaries"
"${PGBINNEW}"/initdb -D "${PGDATANEW}" --encoding=UTF8 --locale=C.UTF-8 --waldir "${WALDIRNEW}"

log "Running pg_upgrade"
"${PGBINNEW}"/pg_upgrade -o "-c timescaledb.restoring=on" -O "-c timescaledb.restoring=on" -O "-c shared_preload_libraries=timescaledb" --link

log "Moving directories around"
mv "${PGDATAOLD}" "${PGDATAOLD}".old
mv "${WALDIROLD}" "${WALDIROLD}".old
mv "${PGDATANEW}" "${PGDATAOLD}"
mv "${WALDIRNEW}" "${WALDIROLD}"

log "Point the pg_wal symlink to the correct location"
rm "${PGDATAOLD}/pg_wal"
ln -s "${WALDIROLD}" "${PGDATAOLD}/pg_wal"

log "Starting PostgreSQL using new binaries"

"${PGBINNEW}/pg_ctl" -D "${PGDATAOLD}" start
while ! pg_isready -U postgres; do sleep 1; done;

log "Upgrading pgbackrest stanza"
pgbackrest stanza-upgrade || true

log "Analyzing all database to update statistics"
./analyze_new_cluster.sh || true

log "Stopping PostgreSQL using new binaries"
"${PGBINNEW}/pg_ctl" -D "${PGDATAOLD}" stop


log "Removing annotations from the ${PATRONI_SCOPE}-config endpoint to clear System ID"
SERVICEACCOUNT=/run/secrets/kubernetes.io/serviceaccount
curl --cacert ${SERVICEACCOUNT}/ca.crt \
    --request PATCH \
    --header "Authorization: Bearer $(cat ${SERVICEACCOUNT}/token)" \
    --header "Accept: application/json, /" \
    --header "Content-Type: application/strategic-merge-patch+json" \
    --data '{"metadata":{"annotations":{"$patch": "delete", "initialize": "nonsense"}}}' \
    "https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/namespaces/${PATRONI_KUBERNETES_NAMESPACE}/endpoints/${PATRONI_SCOPE}-config"

log "Waiting for 30 seconds to ensure an active master can update the config endpoint"
sleep 30

echo "${STARTED}"
log "Upgraded successfully from PostgreSQL ${OLDVERSION} to ${NEWVERSION}"

exit 0
