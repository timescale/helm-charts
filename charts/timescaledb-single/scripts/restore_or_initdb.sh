#!/bin/sh

: "${ENV_FILE:=${HOME}/.pod_environment}"
if [ -f "${ENV_FILE}" ]; then
    echo "Sourcing ${ENV_FILE}"
    . "${ENV_FILE}"
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - restore_or_initdb - $1"
}

# PGDATA and WALDIR are set in the StatefulSet template and are sourced from the ENV_FILE
# PGDATA=
# WALDIR=

# A missing PGDATA points to Patroni removing a botched PGDATA, or manual
# intervention. In this scenario, we need to recreate the DATA and WALDIRs
# to keep pgBackRest happy
[ -d "${PGDATA}" ] || install -o postgres -g postgres -d -m 0700 "${PGDATA}"
[ -d "${WALDIR}" ] || install -o postgres -g postgres -d -m 0700 "${WALDIR}"

if [ "${BOOTSTRAP_FROM_BACKUP}" = "1" ]; then
    log "Attempting restore from backup"
    # we want to override the environment with the environment
    # shellcheck disable=SC2046
    export $(env -i envdir /etc/pgbackrest/bootstrap env) > /dev/null
    # PGBACKREST_REPO1_PATH is set in the StatefulSet template and sourced from the ENV_FILE

    if [ -z "${PGBACKREST_REPO1_PATH}" ]; then
        log "Unconfigured repository path"
        cat << "__EOT__"

TimescaleDB Single Helm Chart error:

You should configure the bootstrapFromBackup in your Helm Chart section by explicitly setting
the repo1-path to point to the backups.

For more information, consult the admin guide:
https://github.com/timescale/helm-charts/blob/main/charts/timescaledb-single/docs/admin-guide.md#bootstrap-from-backup

__EOT__

        exit 1
    fi

    log "Listing available backup information"
    pgbackrest info
    EXITCODE=$?
    if [ ${EXITCODE} -ne 0 ]; then
        exit $EXITCODE
    fi

    pgbackrest --log-level-console=detail restore
    EXITCODE=$?
    if [ ${EXITCODE} -eq 0 ]; then
        log "pgBackRest restore finished succesfully, starting instance in recovery"
        # We want to ensure we do not overwrite a current backup repository with archives, therefore
        # we block archiving from succeeding until Patroni can takeover
        touch "${PGDATA}/recovery.signal"
        pg_ctl -D "${PGDATA}" start -o '--archive-command=/bin/false'

        while ! pg_isready -q; do
            log "Waiting for PostgreSQL to become available"
            sleep 3
        done

        # It is not trivial to figure out to what point we should restore, pgBackRest
        # should be fetching WAL segments until the WAL is exhausted. We'll ask pgBackRest
        # what the Maximum Wal is that it currently has; as soon as we see that, we can consider
        # the restore to be done
        while true; do
            MAX_BACKUP_WAL="$(pgbackrest info --output=json | python3 -c "import json,sys;obj=json.load(sys.stdin); print(obj[0]['archive'][0]['max']);")"
            log "Testing whether WAL file ${MAX_BACKUP_WAL} has been restored ..."
            [ -f "${PGDATA}/pg_wal/${MAX_BACKUP_WAL}" ] && break
            sleep 30;
        done

        # At this point we know the final WAL archive has been restored, we should be done.
        log "The WAL file ${MAX_BACKUP_WAL} has been successully restored, shutting down instance"
        pg_ctl -D "${PGDATA}" promote
        pg_ctl -D "${PGDATA}" stop -m fast
        log "Handing over control to Patroni ..."
    else
        log "Bootstrap from backup failed"
        exit 1
    fi
else
    # Patroni attaches --scope and --datadir to the arguments, we need to strip them off as
    # initdb has no business with these parameters
    initdb_args=""
    for value in "$@"
    do
        case $value in
            "--scope"*)
                ;;
            "--datadir"*)
                ;;
            *)
                initdb_args="${initdb_args} $value"
                ;;
        esac
    done

    log "Invoking initdb"
    # shellcheck disable=SC2086
    initdb --auth-local=peer --auth-host=md5 --pgdata="${PGDATA}" --waldir="${WALDIR}" ${initdb_args}
fi

echo "include_if_exists = '${TSTUNE_FILE}'" >> "${PGDATA}/postgresql.conf"
