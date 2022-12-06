#!/bin/sh
: "${ENV_FILE:=${HOME}/.pod_environment}"
if [ -f "${ENV_FILE}" ]; then
    echo "Sourcing ${ENV_FILE}"
    . "${ENV_FILE}"
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - post_init - $1"
}

log "Creating extension TimescaleDB in template1 and postgres databases"
psql -d "$URL" <<__SQL__
    \connect template1
    -- As we're still only initializing, we cannot have synchronous_commit enabled just yet.
    SET synchronous_commit to 'off';
    CREATE EXTENSION timescaledb;

    \connect postgres
    SET synchronous_commit to 'off';
    CREATE EXTENSION timescaledb;
__SQL__

# POSTGRES_TABLESPACES is a comma-separated list of tablespaces to create
# variable is passed in StatefulSet template
: "${POSTGRES_TABLESPACES:=""}"
for tablespace in $POSTGRES_TABLESPACES
do
    log "Creating tablespace ${tablespace}"
    tablespacedir="${PGDATA}/tablespaces/${tablespace}/data"
    psql -d "$URL" --set tablespace="${tablespace}" --set directory="${tablespacedir}" --set ON_ERROR_STOP=1 <<__SQL__
    SET synchronous_commit to 'off';
    CREATE TABLESPACE :"tablespace" LOCATION :'directory';
__SQL__
done

# This directory may contain user defined post init steps
for file in /etc/timescaledb/post_init.d/*
do
    [ -d "$file" ] && continue
    [ ! -r "$file" ] && continue

    case "$file" in
    *.sh)
        if [ -x "$file" ]; then
        log "Call post init script [ $file ]"
        "$file" "$@"
        EXITCODE=$?
        else
        log "Source post init script [ $file ]"
        . "$file"
        EXITCODE=$?
        fi
        ;;
    *.sql)
        log "Apply post init sql [ $file ]"
        # Disable synchronous_commit since we're initializing
        PGOPTIONS="-c synchronous_commit=local" psql -d "$URL" -f "$file"
        EXITCODE=$?
        ;;
    *.sql.gz)
        log "Decompress and apply post init sql [ $file ]"
        gunzip -c "$file" | PGOPTIONS="-c synchronous_commit=local" psql -d "$URL"
        EXITCODE=$?
        ;;
    *)
        log "Ignore unknown post init file type [ $file ]"
        EXITCODE=0
        ;;
    esac
    EXITCODE=$?
    if [ "$EXITCODE" != "0" ]
    then
        log "ERROR: post init script $file exited with exitcode $EXITCODE"
        exit $EXITCODE
    fi
done

# We exit 0 this script, otherwise the database initialization fails.
exit 0
