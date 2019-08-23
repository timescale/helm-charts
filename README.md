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
NAME                    READY   STATUS              RESTARTS   AGE
pod/example-patroni-0   1/1     Running             0          79s
pod/example-patroni-1   1/1     Running             0          53s
pod/example-patroni-2   0/1     ContainerCreating   0          23s


NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP                PORT(S)          AGE
service/example-patroni          LoadBalancer   10.100.157.80   verylongname.example.com   5432:32641/TCP   79s
service/example-patroni-config   ClusterIP      None            <none>                     <none>           53s




NAME                               READY   AGE
statefulset.apps/example-patroni   2/3     80s

```

## Initial connection to the HA Cluster
And you should be able to connect to the provided service using the external name.
The postgres password is set in `values.yaml`, but you may have changed that:
```yaml
credentials:
  superuser: tea
```
```bash
psql -h verylongname.example.com -U postgres
```
```
Password for user postgres: 

postgres=#
```

From here, you can start creating users and databases, for example, using the above `psql` session:
```sql
CREATE USER example WITH PASSWORD 'thisIsInsecure';
CREATE DATABASE example OWNER example;
-- Installing TimescaleDB should be done by a superuser, so we connect to the new db and install it
\connect example postgres
CREATE EXTENSION timescaledb;
\q
```

## Connect to the example database with the example user
```bash
psql -h verylongname.example.com -U example -d example
```
This should get you into the example database, from here on you can follow
our [getting started](https://docs.timescale.com/latest/getting-started/creating-hypertables) to create hypertables etc.