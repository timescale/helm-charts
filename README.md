# TimescaleDB Kubernetes

This repository contains Helm charts to help with the deployment of
[TimescaleDB](https://github.com/timescale/timescaledb/) on Kubernetes. This
project is currently in active development.

Supported Versions:
- Kubernetes: [AWS EKS](https://aws.amazon.com/eks/), [MicroK8s](https://microk8s.io/), and [minikube](https://github.com/kubernetes/minikube/releases)

# Recipes

| Recipe| TimescaleDB | Description |
|---|---|---|
| [TimescaleDB Single](charts/timescaledb-single) | Based on 1.x | TimescaleDB Single allows you to deploy a highly-available TimescaleDB database configuration. |
| [TimescaleDB Multinode](charts/timescaledb-multinode) | In Development | TimescaleDB Multinode allows you to deploy a multi-node, distributed version of TimescaleDB. |

# Additional documentation

- [Why use TimescaleDB?](https://docs.timescale.com/introduction)
- [Installing TimescaleDB](https://docs.timescale.com/getting-started/installation)
- [Migrating data to TimescaleDB](https://docs.timescale.com/getting-started/migrating-data)
- [Tutorials and sample data](https://docs.timescale.com/tutorials)

## Get Help
- [Slack Channel](https://slack.timescale.com/)
- [GitHub Issues](https://github.com/timescale/timescaledb-kubernetes/issues)

## License

TimescaleDB Kubernetes resources in this repository are released under the [Apache 2.0 license](LICENSE).

## Contributing

If you wish to make contributions to this project, please refer to [Contributor Instructions](CONTRIBUTING.md) for more information.
