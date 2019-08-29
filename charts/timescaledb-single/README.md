# TimescaleDB Single

This directory contains a Helm chart to deploy a three
node [TimescaleDB](https://github.com/timescale/timescaledb/) cluster in a
High Availability (HA) configuration on Kubernetes. This chart will do the following:

- Creates three (by default) pods using a Kubernetes [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).
- Each pod has a container created using the [TimescaleDB Docker image](https://github.com/timescale/timescaledb-docker-ha).
  - TimescaleDB 1.4 (1.4.1) and PG 11 (11.5)
- Each the container runs a TimescaleDB instance and [Patroni](https://patroni.readthedocs.io/en/latest/) agent.
- Each TimescaleDB instance is configured for replication (1 Master + 2 Replicas).

<img src="./timescaledb-single.png" width="640" />

When deploying on AWS EKS:
- The pods will be scheduled on nodes which run in different Availability Zones (AZs).
- An AWS Elastic Load Balancer (ELB) is configured to handle routing incoming traffic to the Master pod.

When configured for Backups to S3:
- Each pod will also include a container running [pgBackRest](https://pgbackrest.org/).
- By default, two [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) are created to handle full weekly and incremental daily backups.
- The backups are stored to an S3 bucket. 

<img src="./timescaledb-single-backups.png" width="640" />


## Installing

To install the chart with the release name `my-release`:

```
helm install --name my-release .
```

To install the chart with randomly generated passwords:

```
helm install --name my-release . \
  --set credentials.superuser="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)",credentials.admin="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)",credentials.standby="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)"
```

## Custom Configuration

The following table lists the configurable parameters of the TimescaleDB Helm chart and their default values.

|       Parameter                   |           Description                       |                         Default                     |
|-----------------------------------|---------------------------------------------|-----------------------------------------------------|
| `nameOverride`                    | Override the name of the chart              | `timescaledb`                                       |
| `fullnameOverride`                | Override the fullname of the chart          | `nil`                                               |
| `replicaCount`                    | Amount of pods to spawn                     | `3`                                                 |
| `image.repository`                | The image to pull                           | `timescaledev/timescaledb-ha`                       |
| `image.tag`                       | The version of the image to pull            | `78603166-pg11`                                     |
| `image.pullPolicy`                | The pull policy                             | `IfNotPresent`                                      |
| `credentials.superuser`           | Password of the superuser                   | `tea`                                               |
| `credentials.admin`               | Password of the admin                       | `cola`                                              |
| `credentials.standby`             | Password of the replication user            | `pinacolada`                                        |
| `backup.enable`                   | Schedule backups to occur                   | `false`                                             |
| `backup.s3Bucket`                 | The S3 bucket in which to store backups     |                                                     |
| `backup.accessKeyId`              | The Access Key ID to authenticate the IAM user for the backup |                                   |
| `backup.secretAccessKey`          | The Key Secret to authenticate the IAM user |                                                     |
| `backup.jobs`                     | A list of backup schedules and types        | 1 full weekly backup, 1 incremental daily backup    |
| `kubernetes.dcs.enable`           | Using Kubernetes as DCS                     | `true`                                              |
| `kubernetes.configmaps.enable`    | Using Kubernetes configmaps instead of endpoints | `false`                                        |
| `env`                             | Extra custom environment variables          | `{}`                                                |
| `patroni`                         | Specify your specific [Patroni Configuration](https://patroni.readthedocs.io/en/latest/SETTINGS.html) | Some defaults to ensure to load TimescaleDB         |
| `resources`                       | Any resources you wish to assign to the pod | `{}`                                                |
| `nodeSelector`                    | Node label to use for scheduling            | `{}`                                                |
| `tolerations`                     | List of node taints to tolerate             | `[]`                                                |
| `affinityTemplate`                | A template string to use to generate the affinity settings | Anti-affinity preferred on hostname  |
| `affinity`                        | Affinity settings. Overrides `affinityTemplate` if set. | `{}`                                    |
| `schedulerName`                   | Alternate scheduler name                    | `nil`                                               |
| `persistentVolume.accessModes`    | Persistent Volume access modes              | `[ReadWriteOnce]`                                   |
| `persistentVolume.annotations`    | Annotations for Persistent Volume Claim`    | `{}`                                                |
| `persistentVolume.mountPath`      | Persistent Volume mount root path           | `/home/postgres/pgdata`                             |
| `persistentVolume.size`           | Persistent Volume size                      | `2Gi`                                               |
| `persistentVolume.storageClass`   | Persistent Volume Storage Class             | `volume.alpha.kubernetes.io/storage-class: default` |
| `persistentVolume.subPath`        | Subdirectory of Persistent Volume to mount  | `""`                                                |
| `rbac.create`                     | Create required role and rolebindings       | `true`                                              |
| `serviceAccount.create`           | If true, create a new service account	      | `true`                                              |
| `serviceAccount.name`             | Service account to be used. If not set and `serviceAccount.create` is `true`, a name is generated using the fullname template | `nil` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```
helm install --name my-release -f values.yaml .
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Resources

To list the Kubernetes resources created:

```
kubectl get all -l release=my-release
```

```console
NAME                        READY   STATUS              RESTARTS   AGE
pod/example-timescaledb-0   1/1     Running             0          79s
pod/example-timescaledb-1   1/1     Running             0          53s
pod/example-timescaledb-2   1/1     Running             0          23s


NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP                PORT(S)          AGE
service/my-release-timescaledb          LoadBalancer   10.100.157.80   verylongname.example.com   5432:32641/TCP   79s
service/my-release-timescaledb-config   ClusterIP      None            <none>                     <none>           53s

NAME                                   READY   AGE
statefulset.apps/my-release-timescaledb   3/3     80s
```


## Replication

TimescaleDB is built on top of PostgreSQL. To ensure a high-availability configuration,
[Patroni](https://github.com/zalando/patroni) is used. Patroni is responsible for electing
a PostgreSQL master pod. After election, Patroni adds a `spilo-role=master` label to the elected master and set the label
to `spilo-role=replica` for all replicas. Simultaneously it will
update the `<release-name>-timescaledb` endpoint to let the service route traffic to the elected master.

```
kubectl get pods -l spilo-role -L spilo-role
```

```console
NAME                       READY   STATUS    RESTARTS   AGE     SPILO-ROLE
my-release-timescaledb-0   1/1     Running   0          9m10s   master
my-release-timescaledb-1   1/1     Running   0          8m40s   replica
my-release-timescaledb-2   1/1     Running   0          8m5s    replica
```

## Create backups to S3
The backup is disabled by default, the following items are required for you to enable creating backups to S3:

- an S3 bucket available for your backups
- an [IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)
- a [S3 Bucket Policy](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/add-bucket-policy.html) that allows the IAM user read and write access to (parts of) the S3 bucket
- access key that allows you to login as the IAM user

If you (re)deploy your database with this configuration snippet in the values file, the backup should start working.

```yaml
# Filename: myvalues.yaml
backup:
  enable: True
  s3Bucket: this_bucket_may_not_exist
  accessKeyId: 9E1R2CUZBXJVYSBYRWTB
  secretAccessKey: 5CrhvJD08bp9emxI+D48GXfDdtl823nlSRRv7dmB
```
```
helm upgrade --install example -f myvalues.yaml
```

### Control the backup schedule
If you want to alter the backup jobs, or their schedule, you can override the `backup.jobs` in your configuration, for example:

```yaml
backup:
  jobs:
    - name: full-daily
      type: full
      schedule: "18 0 * * *"
    - name: incremental-hourly
      type: incr
      schedule: "18 1-23 * * *"
```
- *name*: Needs to adhere to the [Kubernetes name conventions](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names)
- *type*: choose from `full`, `incr` or `diff`, as explained in the [pgBackRest documentation](https://pgbackrest.org/user-guide.html)
- *schedule*: A schedule, specified in [cron format](https://en.wikipedia.org/wiki/Cron)

## Cleanup

To remove the spawned pods you can run a simple `helm delete <release-name>`.

Helm will however preserve created persistent volume claims. To also remove the persistent
volumes, execute the commands below.

```
helm delete my-release
kubectl delete pvc -l release=my-release
```

## Connecting to TimescaleDB

By default, the `postgres` password is set in `values.yaml`:

```yaml
credentials:
  superuser: tea
```

Using the External IP for the service (which will route thru the LoadBalancer to the Master), you
can connect via `psql` using the following:

```bash
psql -h verylongname.example.com -U postgres
```
```console
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

Connect to the example database with the example user:

```bash
psql -h verylongname.example.com -U example -d example
```

This should get you into the example database, from here on you can follow
our [TimescaleDB > Getting Started](https://docs.timescale.com/latest/getting-started/creating-hypertables) to create hypertables
and start using TimescaleDB.

### Connecting from inside the Cluster

To access the database from inside the cluster, spin up another Pod to run `psql`:

```
kubectl run -i --tty --rm psql --image=postgres --restart=Never -- bash -il
```

Then, from inside the pod, connect to PostgreSQL:

```console
$ psql -U admin -h my-release-timescaledb.default.svc.cluster.local postgres
<admin password from values.yaml>
postgres=>
```


