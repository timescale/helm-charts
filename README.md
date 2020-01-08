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

# Repository

The Charts are available in a Helm Chart Repository, which is part of this project.
The following command will make this repository ready for use:
```
helm repo add timescaledb 'https://github.com/timescale/timescaledb-kubernetes/charts/repo'
```
For more information, have a look at the [Using Helm](https://helm.sh/docs/intro/using_helm/#helm-repo-working-with-repositories) documentation.

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
