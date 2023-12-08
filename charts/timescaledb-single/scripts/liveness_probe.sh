#!/bin/bash
#
# This liveness probe, as used in `statefulset-timescaledb.yaml` for the `timescaledb` container,
# will only be executed after the readiness probe has reckoned a successful readiness state.
# As such, our first order of operation is to check if pg_isready. If so, then we just return.
# If it is determined that PG is not ready, then we proceed to check a few other conditions
# to determine if it is safe for us to reckon a lack of liveness.
#
# This script can also be extended with custom logic. The first use case for custom logic is to
# optionally shutdown the linkerd-proxy sidecar of this pod when running with linkerd.

# First check if pg_isready, just like the readiness probe.
if pg_isready -h /var/run/postgresql; then
    echo "pg is ready, exit 0"
    exit 0
fi

# PG is not ready, then check patroni.
if curl -s -f -XGET http://localhost:8008/liveness; then
    echo "patroni is live, exit 0"
    exit 0
fi

# So far, PG is not ready, and patroni is either gone or reporting a non 2xx status.
# Check to see if the patroni process is still around.
if pgrep -f "patroni"; then
    echo "patroni is still kicking, exit 0"
    exit 0
fi

# NOTE that pgbackrest archival of WAL is spawned by the postgres process which is managed
# by patroni. If there is no patroni process, then we shouldn't have any child processes
# still around. As such, the last pgrep for patroni should obviate the need for directly
# checking for archival processes still lingering about.
#
# However, there is such a thing as zombie processes ... so let's just check anyway.
if pgrep "pgbackrest"; then
    echo "pgbackrest is still kicking, exit 0"
    exit 0
fi

echo "PG is not ready, patroni process is gone, no pgbackrest operations detected, this thing is dead"

# First param indicates that we should attempt to shutdown the local linkerd-proxy on exit.
if [[ $1 == "1" ]]; then
    echo "executing custom cleanup routine, shutting down local linkerd-proxy"
    curl -s -m 5 -X POST http://localhost:4191/shutdown
fi

exit 1
