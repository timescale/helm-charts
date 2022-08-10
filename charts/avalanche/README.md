<!---
This file and its contents are licensed under the Apache License 2.0.
Please see the included NOTICE for copyright information and LICENSE for a copy of the license.
-->

# Avalanche

##### Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
  - [Installing from the Timescale Helm Repo](#installing-from-the-timescale-helm-repo)

## Introduction
This directory contains a Helm chart to deploy [Avalanche](https://github.com/prometheus-community/avalanche),
used for load testing and benchmarking Prometheus and remote write compatible storage backends such as Promscale.

## Installation

To install the chart with the release name `my-release` You can install the chart with:
```console
helm install --name my-release charts/avalanche
```

You can override parameters using the `--set key=value[,key=value]` argument to `helm install`,
e.g., to disable service account creation:

```console
helm install --name my-release charts/avalanche --set serviceAccount.create=false
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,
```console
helm install --name my-release -f myvalues.yaml charts/avalanche
```

### Installing from the Timescale Helm Repo

We have a Helm Repository that you can use, instead of cloning this Git repo. 

First add the repository with:
```console
helm repo add timescale 'https://charts.timescale.com'
```

Next proceed to install the chart:

```console
helm install my-release timescale/avalanche
```

To keep the repo up to date with new versions you can do:
```console
helm repo update
```
