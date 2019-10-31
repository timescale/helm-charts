# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

These are changes that will probably be included in the next release.

### Added
### Changed
### Removed
### Fixed

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
