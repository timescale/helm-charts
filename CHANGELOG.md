# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
### Changed
 * Set autotune max\_wal\_size to 60% (instead of 80%) for a dedicated WAL volume
### Removed
### Fixed
 * Prevent creation of replication slots for Jobs

## [v0.5.2] -  2020-01-31

> NOTICE: When migrating from a < 0.5.x chart, the primary Service needs to be removed before
> invoking `helm update`, as the update will otherwise fail.

### Added
 * Support for multiple tablespaces at initialization time
### Fixed
 * CronJob triggering the backup (the POST request was not valid json)

## [v0.5.1] -  2020-01-21

> NOTICE: When migrating from a < 0.5.x chart, the primary Service needs to be removed before
> invoking `helm update`, as the update will otherwise fail.

### Added
 * Optionally tune PostgreSQL settings (e.g. shared\_buffers, work\_mem, max\_wal\_size) using timescaledb-tune
 * The charts are now also available in a Helm Repository
### Changed
 * The Service for the primary is now also created and managed by Helm
 * Use TimescaleDB 1.6 as the default version
### Fixed
 * Configuration changes in `patroni.bootstrap.dcs` now propagate to PostgreSQL servers, previously these settings
   were only read during bootstrap.
 * Patroni can now also use the endpoint in OpenShift
 * `pgBackRest` will not check its stanza on a replica
 * Default Backup Schedule is now set to 1 full a week and 6 incremental backups. (The previous definition mixed up
   day of month with day of week)

## [v0.5.0] - Never released publicly

## [v0.4.0] - 2019-12-12

### Added
* Enabling Prometheus now creates a Service that can be properly scraped
* Support for NetworkPolicy
### Changed
* Switch services to ClusterIP if the Load Balancer is set to disabled
* Create PGDATA and WALDIR before a pgBackRest restore

## [v0.3.0] - 2019-11-25

> NOTICE: When migrating from a 0.2.x chart to a 0.3 chart, please take the following into account:

- if you use the `env` key in your values, you should rewrite them from a
   plain dict into a list of [EnvVar](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.16/#envvar-v1-core)

### Added

* Add ability to [annotate](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) pods in the StatefulSet
* Add ability to run any script as callback, if exposed as a ConfigMap

### Changed
 * Reduce loglevel of Patroni from INFO to WARNING
 * The values.yaml env key should be expressed as a list of [EnvVar](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.16/#envvar-v1-core)s
 * Refer to the latest minor versions for PostgreSQL & TimescaleDB

### Fixed
 * Set `unix_socket_permissions` using PostgreSQL parameters instead

## [v0.2.5] - 2019-11-06

### Added
 * Add [readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes) for PostgreSQL
 * Allow a (debug) command to run at container startup
 * Add a [Headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) (by default),
   with the option to convert it into a Load Balancer
### Changed
 * Rename backup.enable to backup.enabled for consistency, the old naming does still work.
 * Rename postgresExporter to prometheus

## [v0.2.4] - 2019-11-05

### Changed
 * Use 2.0.0-beta3 Docker Image for multinode
 * Allow [postgres-exporter](https://github.com/wrouesnel/postgres_exporter) to run as a sidecar

## [v0.2.3] - 2019-11-01

### Added
 * Allow annotations to be specified for the Load Balancer in the values.yaml file

## [v0.2.2] - 2019-10-31

### Changed
 * Use TimescaleDB 1.5 Docker image by default

## [v0.2.1] - 2019-10-22

### Changed
 * Point to the -latest Docker image tag for multinode by default
### Fixed
 * Always explicitly set wal directory
 * (multinode) Drop the TimescaleDB extension from the Data Nodes to allow a clean bootstrap to be done

## [v0.2.0] - 2019-10-16
### Added
 * A preliminary multinode Helm chart
 * Architecture diagrams
 * Allow multiple volumes for the data directory and the WAL directory
 * Documentation pgBackRest restore outside of Kubernetes environment

### Changed
 * The defined Patroni configuration is passed on (using a ConfigMap) to Patroni
 * Secrets required by Patroni are injected using environment variables
 * The defined pgBackRest configuration is passed on to pgBackRest (using a Secret as it holds credentials)
 * The entrypoint no longer points to scripts in the Docker image, this pretty much allows any Docker image
     to be used, as long as it contains PostgreSQL, TimescaleDB, and pgBackRest
 * Best practice PostgreSQL parameters, e.g. enable logging of connections by default
 * Open Sourced this repository as Apache License 2.0

## [v0.1.0] - 2019-09-04

### Added
 *  Helm chart for `timescaledb-single`
 *  Documentation for the `timescaledb-single` Helm chart
