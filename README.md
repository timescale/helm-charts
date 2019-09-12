# TimescaleDB Kubernetes

This repository contains Helm charts to help with the deployment of [TimescaleDB](https://github.com/timescale/timescaledb/) on Kubernetes.

This project is currently in active development. This is an alpha version.

Supported Versions:
- Kubernetes: [AWS EKS](https://aws.amazon.com/eks/), [MicroK8s](https://microk8s.io/), [minikube](https://github.com/kubernetes/minikube/releases)

# Recipes

| Recipe| TimescaleDB | Description |
|---|---|---|
| [TimescaleDB Single](charts/timescaledb-single) | Based on 1.x | TimescaleDB Single allows you to deploy a highly-available TimescaleDB database configuration. |
| [TimescaleDB Multinode](charts/timescaledb-multinode) | In Development | TimescaleDB Multinode allows you to deploy a multi-node, distributed version of TimescaleDB. |

# Additional documentation

- [Why use TimescaleDB?](https://docs.timescale.com/introduction)
- [Migrating from PostgreSQL](https://docs.timescale.com/getting-started/setup/migrate-from-postgresql)
- [Writing data](https://docs.timescale.com/using-timescaledb/writing-data)
- [Querying and data analytics](https://docs.timescale.com/using-timescaledb/reading-data)
- [Tutorials and sample data](https://docs.timescale.com/tutorials)
