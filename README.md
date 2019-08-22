# TimescaleDB Kubernetes

This repository contains helm charts that allow you to quickly get started with running TimescaleDB in your Kubernetes
cluster.

# Recipes

## Install a HA cluster without any custom configuration
```
helm install --name example charts/patroni/
```

This will spin up a few pods that are providing a HA TimescaleDB cluster. An example listing of what has been installed
looks like this:

```
$ kubectl get all -l release=example
NAME                    READY   STATUS    RESTARTS   AGE
pod/example-patroni-0   1/1     Running   0          82s
pod/example-patroni-1   1/1     Running   0          80s
pod/example-patroni-2   1/1     Running   0          79s

NAME                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/example-patroni          ClusterIP   10.152.183.201   <none>        5432/TCP   82s
service/example-patroni-config   ClusterIP   None             <none>        <none>     78s

NAME                               READY   AGE
statefulset.apps/example-patroni   3/3     82s
```
