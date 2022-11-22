<!---
This file and its contents are licensed under the Apache License 2.0.
Please see the included NOTICE for copyright information and LICENSE for a copy of the license.
-->

# Parca Server

##### Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
  - [Installing from the Timescale Helm Repo](#installing-from-the-timescale-helm-repo)

## Introduction
This directory contains a Helm chart to deploy [Parca Agent](https://github.com/parca-dev/parca-agent),
used for Open Source infrastructure-wide continous profiling.

## Installation

To install the chart with the release name `my-release`, you can clone the git repo and run the command:
```console
helm install --name my-release ./charts/parca-agent
```

You can override parameters using the `--set key=value[,key=value]` argument to `helm install`,
e.g., to disable service account creation:

```console
helm install --name my-release ./charts/parca-agent --set serviceAccount.create=false
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,
```console
helm install --name my-release -f myvalues.yaml ./charts/parca-agent
```

### Installing from the Timescale Helm Repo

We have a Helm Repository that you can use, instead of cloning this Git repo. 

First add the repository with:
```console
helm repo add timescale 'https://charts.timescale.com'
```

Next proceed to install the chart:

```console
helm install my-release timescale/parca-agent
```

To keep the repo up to date with new versions you can do:
```console
helm repo update
```
