---
name: Bug report
about: Any issue with these Charts
title: "[ISSUE]"
labels: ''
assignees: ''

---

> Have a look at [Troubleshooting](https://github.com/timescale/timescaledb-kubernetes/blob/master/charts/timescaledb-single/admin-guide.md#troubleshooting) or some [Common Issues](https://github.com/timescale/timescaledb-kubernetes/blob/master/charts/timescaledb-single/admin-guide.md#common-issues)

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior, including `helm install` or `helm upgrade` commands

**Expected behavior**
A clear and concise description of what you expected to happen.

**Deployment**
- What is in your `values.yaml`
- What version of the Chart are you using?
- What is your Kubernetes Environment (for exampe: GKE, EKS, minikube, microk8s)

**Deployment**
Please share some details of what is in your Kubernetes environment, for example:

```
kubectl get all,secret,configmap,endpoints,pvc -L role -l release=$RELEASE
```

**Logs**
Please provide some details from the logs, see  [Troubleshooting](https://github.com/timescale/timescaledb-kubernetes/blob/master/charts/timescaledb-single/admin-guide.md#troubleshooting)

**Additional context**
Add any other context about the problem here.
