|![](https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Warning.svg/156px-Warning.svg.png) | This project is no longer maintained.
|---|---|

[![Test Helm Charts](https://github.com/timescale/helm-charts/actions/workflows/tests.yml/badge.svg)](https://github.com/timescale/helm-charts/actions/workflows/tests.yml)
[![Commit activity](https://img.shields.io/github/commit-activity/m/timescale/helm-charts)](https://github.com/timescale/helm-charts/pulse/monthly)
[![License](https://img.shields.io/github/license/timescale/helm-charts)](https://github.com/timescale/helm-charts/blob/main/LICENSE)
[![Slack](https://img.shields.io/badge/chat-join%20slack-brightgreen.svg)](https://timescaledb.slack.com/)

# Timescale Helm Charts

This repository contains Helm charts to help with the deployment of
[TimescaleDB](https://github.com/timescale/timescaledb/) on Kubernetes. This
project is currently in active development.

## Repository

The Charts are available in a Helm Chart Repository hosted in Amazon S3 bucket.
The following command will make this repository ready for use:
```
helm repo add timescale 'https://charts.timescale.com/'
```
For more information, have a look at the [Using Helm](https://helm.sh/docs/intro/using_helm/#helm-repo-working-with-repositories) documentation.

## Additional documentation

- [Why use TimescaleDB?](https://docs.timescale.com/timescaledb/latest/overview/core-concepts/#why-use-timescaledb)
- [Installing TimescaleDB](https://docs.timescale.com/timescaledb/latest/how-to-guides/install-timescaledb/self-hosted/)
- [Migrating data to TimescaleDB](https://docs.timescale.com/timescaledb/latest/how-to-guides/migrate-data/)
- [Tutorials and sample data](https://docs.timescale.com/timescaledb/latest/tutorials/)

# License

Resources in this repository are released under the [Apache 2.0 license](LICENSE).

# Contributing

If you wish to make contributions to this project, please refer to [Contributor Instructions](CONTRIBUTING.md) for more information.
