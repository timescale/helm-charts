#!/bin/sh

set -eu

# Exit if required variable is not set externally
: "$TSTUNE_FILE"
: "$WAL_VOLUME_SIZE"
: "$DATA_VOLUME_SIZE"
: "$RESOURCES_CPU_REQUESTS"
: "$RESOURCES_MEMORY_REQUESTS"
: "$RESOURCES_CPU_LIMIT"
: "$RESOURCES_MEMORY_LIMIT"

# Figure out how many cores are available
CPUS="$RESOURCES_CPU_REQUESTS"
if [ "$RESOURCES_CPU_REQUESTS" -eq 0 ]; then
    CPUS="${RESOURCES_CPU_LIMIT}"
fi
# Figure out how much memory is available
MEMORY="$RESOURCES_MEMORY_REQUESTS"
if [ "$RESOURCES_MEMORY_REQUESTS" -eq 0 ]; then
    MEMORY="${RESOURCES_MEMORY_LIMIT}"
fi

# Ensure tstune config file exists
touch "${TSTUNE_FILE}"

# Ensure tstune-generated config is included in postgresql.conf
if [ -f "${PGDATA}/postgresql.base.conf" ] && ! grep "include_if_exists = '${TSTUNE_FILE}'" postgresql.base.conf -qxF; then
    echo "include_if_exists = '${TSTUNE_FILE}'" >> "${PGDATA}/postgresql.base.conf"
fi

# If there is a dedicated WAL Volume, we want to set max_wal_size to 60% of that volume
# If there isn't a dedicated WAL Volume, we set it to 20% of the data volume
if [ "${WAL_VOLUME_SIZE}" = "0" ]; then
    WALMAX="${DATA_VOLUME_SIZE}"
    WALPERCENT=20
else
    WALMAX="${WAL_VOLUME_SIZE}"
    WALPERCENT=60
fi

WALMAX=$(numfmt --from=auto "${WALMAX}")

# Wal segments are 16MB in size, in this way we get a "nice" number of the nearest
# 16MB
# walmax / 100 * walpercent / 16MB # below is a refactored with increased precision
WALMAX=$(( WALMAX * WALPERCENT * 16 / 16777216 / 100  ))
WALMIN=$(( WALMAX / 2 ))

echo "max_wal_size=${WALMAX}MB" >> "${TSTUNE_FILE}"
echo "min_wal_size=${WALMIN}MB" >> "${TSTUNE_FILE}"

# Run tstune
timescaledb-tune -quiet -conf-path "${TSTUNE_FILE}" -cpus "${CPUS}" -memory "${MEMORY}MB" -yes "$@"
