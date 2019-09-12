# TimescaleDB Multinode

This directory contains a Helm chart to deploy a multinode [TimescaleDB](https://github.com/timescale/timescaledb/) cluster.
This chart will do the following:

- Creates a single TimescaleDB Access Node using a Kubernetes [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).
- Creates multiple pods (by default 3) containing Data Nodes using another Kubernetes StatefulSet
- Each pod has a container created using a Docker image which includes the TimescaleDB multinode sources.

When deploying on AWS EKS:
- An AWS Elastic Load Balancer (ELB) is configured to handle routing incoming traffic to the Access Node.

## Installing

To install the chart with the release name `my-release`:

```console
helm install --name my-release .
```

You can override parameters using the `--set key=value[,key=value]` argument to `helm install`,
e.g., to install the chart with randomly generated passwords:

```console
random_password () { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32; }
helm install --name my-release . \
    --set credentials.accessNode.superuser="$(random_password)"
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,
```console
helm install --name my-release -f myvalues.yaml .
```

For details about what parameters you can set, have a look at the [Administrator Guide](admin-guide.md#configure)

## Connecting to TimescaleDBs

To connect to the TimescaleDB instance, we first need to know to which host we need to connect. Use `kubectl` to get that information:
```console
kubectl get service/my-release-timescaledb
```
```
NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP                PORT(S)          AGE
service/my-release-timescaledb   LoadBalancer   10.100.157.80   verylongname.example.com   5432:32641/TCP   79s
```

Using the External IP for the service (which will route through the LoadBalancer to the Access Node), you
can connect via `psql` using the following (default example superuser password is `tea`)

```console
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
```

Connect to the example database with the example user:

```console
psql -h verylongname.example.com -U example -d example
```

This should get you into the example database, from here on you can follow
our [TimescaleDB > Tutorial: Scaling out TimescaleDB](https://docs.timescale.com/clustering/tutorials/clustering)
to create distributed hypertables and start using multinode TimescaleDB.

### Connecting from inside the Cluster

To access the database from inside the cluster, spin up another Pod to run `psql`:

```
kubectl run -i --tty --rm psql --image=postgres --restart=Never -- bash -il
```

Then, from inside the pod, connect to PostgreSQL:

```console
$ psql -U admin -h my-release-timescaledb.default.svc.cluster.local postgres
```

## Cleanup

To remove the spawned pods you can run a simple
```console
helm delete my-release --purge
```
Some items, (pvc's for example) are not immediately removed.
To also purge these items, have a look at the [Administrator Guide](admin-guide.md#cleanup)

## Support
Currently we have the following support channels for this Helm chart:
- Slack: https://slack.timescale.com/
- Email: support@timescale.com

## Further reading

- [Administrator Guide](admin-guide.md)
- [TimescaleDB Documentation](https://docs.timescale.com/clustering/main)
