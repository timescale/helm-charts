#!/bin/sh
set -e

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - bootstrap - $1"
}

terminate() {
    log "Stopping"
    exit 1
}
# If we don't catch these signals, and we're still waiting for PostgreSQL
# to be ready, we will not respond at all to a regular shutdown request,
# therefore, we explicitly terminate if we receive these signals.
trap terminate TERM QUIT

while ! pg_isready -q; do
    log "Waiting for PostgreSQL to become available"
    sleep 3
done

# We'll be lazy; we wait for another while to allow the database to promote
# to primary if it's the only one running
sleep 10

# If we are the primary, we want to create/validate the backup stanza
if [ "$(psql -c "SELECT pg_is_in_recovery()::text" -AtXq)" = "false" ]; then
    pgbackrest check || {
        log "Creating pgBackrest stanza"
        pgbackrest --stanza=poddb stanza-create --log-level-stderr=info || exit 1
        log "Creating initial backup"
        pgbackrest --type=full backup || exit 1
    }
fi

log "Starting pgBackrest api to listen for backup requests"
exec python3 /scripts/pgbackrest-rest.py --stanza=poddb --loglevel=debug
