-- Doing a checkpoint (at the primary and the current instance) before starting
-- the shutdown process will speed up the CHECKPOINT that is part of the shutdown
-- process and the recovery after the pod is rescheduled.
--
-- We issue the CHECKPOINT at the primary always because:
--
-- > Restartpoints can't be performed more frequently than checkpoints in the
-- > master because restartpoints can only be performed at checkpoint records.
-- https://www.postgresql.org/docs/current/wal-configuration.html
--
-- While we're doing these preStop CHECKPOINTs we can still serve read/write
-- queries to clients, whereas as soon as we initiate the shutdown, we terminate
-- connections.
--
-- This therefore reduces downtime for the clients, at the cost of increasing (slightly)
-- the time to stop the pod, and reducing write performance on the primary.
--
-- To further reduce downtime for clients, we will issue a switchover iff we are currently
-- running as the primary. This again should be relatively fast, as we've just issued and
-- waited for the CHECKPOINT to complete.
--
-- This is quite a lot of logic and work in a preStop command; however, if the preStop command
-- fails for whatever reason, the normal Pod shutdown will commence, so it is only able to
-- improve stuff without being able to break stuff.
-- (The $(hostname) inside the switchover call safeguards that we never accidentally
-- switchover the wrong primary).

\pset pager off
\set ON_ERROR_STOP true
\set hostname `hostname`
\set dsn_fmt 'user=postgres host=%s application_name=lifecycle:preStop@%s connect_timeout=5 options=''-c log_min_duration_statement=0'''

SELECT
    pg_is_in_recovery() AS in_recovery,
    format(:'dsn_fmt', patroni_scope,                       :'hostname') AS primary_dsn,
    format(:'dsn_fmt', '/var/run/postgresql', :'hostname') AS local_dsn
FROM
    current_setting('cluster_name') AS cs(patroni_scope)
\gset

\timing on
\set ECHO queries

-- There should be a CHECKPOINT at the primary
\if :in_recovery
    \connect :"primary_dsn"
    CHECKPOINT;
\endif

-- There should also be a CHECKPOINT locally,
-- for the primary, this may mean we do a double checkpoint,
-- but the second one would be cheap anyway, so we leave that as is
\connect :"local_dsn"
SELECT 'Issuing checkpoint';
CHECKPOINT;

\if :in_recovery
    SELECT 'We are a replica: Successfully invoked checkpoints at the primary and locally.';
\else
    SELECT 'We are a primary: Successfully invoked checkpoints, now issuing a switchover.';
    \! curl -s http://localhost:8008/switchover -XPOST -d '{"leader": "$(hostname)"}'
\endif
