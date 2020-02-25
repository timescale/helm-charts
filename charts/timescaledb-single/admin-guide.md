<!---
This file and its contents are licensed under the Apache License 2.0.
Please see the included NOTICE for copyright information and LICENSE for a copy of the license.
-->

# TimescaleDB Single Administrator Guide

##### Table of Contents
- [Connecting](#connecting)
- [Configuration](#configuration)
  - [Creating the Secrets](#creating-the-secrets)
  - [Examples](#examples)
- [Backups](#backups)
- [Cleanup](#cleanup)
- [Callbacks](#callbacks)
- [Troubleshooting](#troubleshooting)
- [Common Issues](#common-issues)

## Configuration
The following table lists the configurable parameters of the TimescaleDB Helm chart and their default values.

|       Parameter                   |           Description                       |                         Default                     |
|-----------------------------------|---------------------------------------------|-----------------------------------------------------|
| `nameOverride`                    | Override the name of the chart              | `timescaledb`                                       |
| `clusterName`                     | Override the name of the PostgreSQL cluster | Equal to the Helm release name                      |
| `fullnameOverride`                | Override the fullname of the chart          | `nil`                                               |
| `replicaCount`                    | Amount of pods to spawn                     | `3`                                                 |
| `version`                         | The major PostgreSQL version to use         | empty, defaults to the Docker image default         |
| `image.repository`                | The image to pull                           | `timescaledev/timescaledb-ha`                       |
| `image.tag`                       | The version of the image to pull            | `pg11-ts1.7`                                        |
| `image.pullPolicy`                | The pull policy                             | `IfNotPresent`                                      |
| `secretNames.credentials`         | Existing secret that contains env vars that influence Patroni (e.g. PATRONI_SUPERUSER_PASSWORD) | `RELEASE-credentials` | 
| `secretNames.certificate`         | Existing `type:kubernetes.io/tls` secret containing a tls.key and tls.crt | `RELEASE-certificate` |
| `secretNames.pgbackrest`          | Existing secret that contains env vars that influence pgBackRest (e.g. PGBACKREST_REPO1_S3_KEY_SECRET) | `RELEASE-pgbackgrest` |
| `backup.enabled`                  | Schedule backups to occur                   | `false`                                             |
| `backup.pgBackRest`               | [pgBackRest global configuration](https://pgbackrest.org/user-guide.html#quickstart/configure-stanza)              | Working defaults |
| `backup.pgBackRest:archive-push`  | [pgBackRest global:archive-push configuration](https://pgbackrest.org/user-guide.html#quickstart/configure-stanza) | empty |
| `backup.pgBackRest:archive-get`   | [pgBackRest global:archive-get configuration](https://pgbackrest.org/user-guide.html#quickstart/configure-stanza)  | empty |
| `backup.jobs`                     | A list of backup schedules and types        | 1 full weekly backup, 1 incremental daily backup    |
| `env`                             | Extra custom environment variables, expressed as [EnvVar](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.16/#envvarsource-v1-core)          | `[]`                                                |
| `envFrom`                         | Extra custom environment variables, expressed as [EnvFrom](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.16/#envfromsource-v1-core)          | `[]`                                                |
| `patroni`                         | Specify your specific [Patroni Configuration](https://patroni.readthedocs.io/en/latest/SETTINGS.html) | A full Patroni configuration |
| `callbacks.configMap`          | A kubernetes ConfigMap containing [Patroni callbacks](#callbacks). You can use templates in the name. | `nil`                         |
| `resources`                       | Any resources you wish to assign to the pod | `{}`                                                |
| `sharedMemory.useMount`           | Mount `/dev/shm` as a Memory disk           | `false`                                             |
| `nodeSelector`                    | Node label to use for scheduling            | `{}`                                                |
| `tolerations`                     | List of node taints to tolerate             | `[]`                                                |
| `affinityTemplate`                | A template string to use to generate the affinity settings | Anti-affinity preferred on hostname and (availability) zone |
| `affinity`                        | Affinity settings. Overrides `affinityTemplate` if set. | `{}`                                    |
| `schedulerName`                   | Alternate scheduler name                    | `nil`                                               |
| `loadBalancer.enabled`            | If enabled, creates a LB for the primary    | `true`                                              |
| `loadBalancer.annotations`        | Pass on annotations to the Load Balancer    | An AWS ELB annotation to increase the idle timeout  |
| `loadBalancer.extraSpec`          | Extra configuration for service spec        | `nil`                                               |
| `networkPolicy.enabled`           | If enabled, creates a NetworkPolicy for controlling network access | `false`
| `networkPolicy.ingress`           | A list of Ingress rules to extend the base NetworkPolicy | `nil`
| `networkPolicy.prometheusApp`     | Name of Prometheus app to allow it to scrape exporters | `prometheus`
| `replicaLoadBalancer.enabled`     | If enabled, creates a LB for replica's only | `false`                                             |
| `replicaLoadBalancer.annotations` | Pass on annotations to the Load Balancer    | An AWS ELB annotation to increase the idle timeout  |
| `replicaLoadBalancer.extraSpec`   | Extra configuration for replica service spec | `nil`                                              |
| `prometheus.enabled`              | If enabled, run a [postgres\_exporter](https://github.com/wrouesnel/postgres_exporter) sidecar | `false` |
| `prometheus.image.repository`     | The postgres\_exporter docker repo          | `wrouesnel/postgres_exporter`                       |
| `prometheus.image.tag`            | The tag of the postgres\_exporter image     | `v0.7.0`                                            |
| `prometheus.image.pullPolicy`     | The pull policy for the postgres\_exporter  | `IfNotPresent`                                      |
| `persistentVolumes.data.enabled`  | If enabled, use a Persistent Data Volume    | `true`                                              |
| `persistentVolumes.data.mountPath`| Persistent Data Volume mount root path      | `/var/lib/postgresql/`                              |
| `persistentVolumes.wal.enabled`   | If enabled, use a Persistent Wal Volume. If disabled, WAL will be on the Data Volume | `true`     |
| `persistentVolumes.wal.mountPath` | Persistent Wal Volume mount root path       | `/var/lib/postgresql/wal/`                          |
| `persistentVolumes.<name>.accessModes` | Persistent Volume access modes         | `[ReadWriteOnce]`                                   |
| `persistentVolumes.<name>.annotations` | Annotations for Persistent Volume Claim| `{}`                                                |
| `persistentVolumes.<name>.size`   | Persistent Volume size                      | `2Gi`                                               |
| `persistentVolumes.<name>.storageClass`| Persistent Volume Storage Class        | `volume.alpha.kubernetes.io/storage-class: default` |
| `persistentVolumes.<name>.subPath`| Subdirectory of Persistent Volume to mount  | `""`                                                |
| `persistentVolumes.tablespaces`   | A mapping of tablespaces and Volumes        | `nil`, see [multiple-tablespaces.yaml](values/multiple-tablespaces.yaml) for a full example |
| `rbac.create`                     | Create required role and rolebindings       | `true`                                              |
| `serviceAccount.create`           | If true, create a new service account       | `true`                                              |
| `serviceAccount.name`             | Service account to be used. If not set and `serviceAccount.create` is `true`, a name is generated using the fullname template | `nil` |
| `timescaledbTune.enabled`         | If true, runs `timescaledb-tune` before starting PostgreSQL | `false`                             |
| `unsafe`                          | If true, will generate random a random certificate and random credentials, removing the need for the pre-installation steps with secrets | `false`. This should only be `true` for throw-away (evaluation) deployments |

### Creating the Secrets

The chart expects that the Secret objects referenced in `secretNames.credentials`, `secretNames.certificate` and  `secretNames.pgbackrest` are already created when deploying. The values in these secrets will be used as ENV variables to securely configure the deployment.

We've included a helper script `generate_kustomization.sh` to help generate a [kustomization](https://kustomize.io) for a single deployment. The script generates configuration for:
* strong random passwords for the database
* a self-signed SSL certificate (for demo and dev purposes)
* backup (if enabled)

The script is interactive and (if you wish to enable backups) will ask you to enter your values 
for the pgBackRest S3 config (like bucket, region, endpoint, key and secret).
It will also ask if you want the script to install the secrets directly.

```sh
charts/timescaledb-single/generate_kustomization.sh <release name>
```

The script can install the secrets immediately, it creates the following secrets:

#### Credentials 

This Secret should contain the EVN vars that will influence Patroni. It should at least contain the passwords for the 3 different database users this chart creates: postgres (superuser), admin, and standby (replication). For example, the data of the secret can be:
  ```yaml
  data:
    PATRONI_SUPERUSER_PASSWORD=base64-encoded-strong-pass
    PATRONI_REPLICATION_PASSWORD=base64-encoded-strong-pass
    PATRONI_admin_PASSWORD=base64-encoded-strong-pass
  ```

#### Certificate

This Secret should be of `type: kubernetes.io/tls` with two items: `tls.crt` and `tls.key`. The certificate is used for the database connections.

> **NOTICE**: The `generate_kustomization.sh` script generates self-signed certificates that should 
only be used for development and demo purposes. 
The certificate should be replaced by a signed certificate, signed by a Certificate Authority (CA) that you trust.

#### pgBackRest 

This Secret is optional, and required only when backups are enabled (`backup.enabled=true`). 
It should contain the ENV vars that influence pgBackRest (e.g. PGBACKREST_REPO1_S3_KEY_SECRET)

The values in this Secret should specify sensitive variables like S3_KEY and S3_KEY_SECRET.
For example:
  ```yaml
  data:
    PGBACKREST_REPO1_S3_BUCKET: <base64 encoded my_example_s3_bucket_for_backups>
    PGBACKREST_REPO1_S3_ENDPOINT: <base64 encoded s3.amazonaws.com>
    PGBACKREST_REPO1_S3_REGION: <base64 encoded us-east-2>
    PGBACKREST_REPO1_S3_KEY: <base64 encoded examplekeyid>
    PGBACKREST_REPO1_S3_KEY_SECRET: <base64 encoded examplesecret+D48GXfDdtlnlSdmB>
  ```

Another example, if you want to include encryption of your backups by pgBackRest, is to include these parameters:

```yaml
  data:
    PGBACKREST_REPO1_CIPHER_TYPE: <base64 encoded aes-256-cbc>
    PGBACKREST_REPO1_CIPHER_PASS: <base64 encoded encryption passphrase>
```

For a list of all the pgBackRest command configuration options that you can set take a look 
at: https://pgbackrest.org/command.html#introduction 
  > Any option may be set in an environment variable using the PGBACKREST_ prefix and the option name in all caps replacing - with _, e.g. pg1-path becomes PGBACKREST_PG1_PATH and stanza becomes PGBACKREST_STANZA...
  >
  > ... more at the link

### Examples
- Override value using commandline parameters
    ```console
    helm upgrade --install my-release charts/timescaledb-single --set image.tag=pg11.7-ts1.6.0 --set image.pullPolicy=Always
    ```
- Override values using `myvalues.yaml`
    ```yaml
    # Filename: myvalues.yaml
    image:
      tag: pg11.7-ts1.6.0
      pullPolicy: Always
    patroni:
      postgresql:
        parameters:
          checkpoint_completion_target: .9
    ```
    ```console
    helm upgrade --install my-release charts/timescaledb-single -f myvalues.yaml
    ```
- Use an example values file to match an AWS EC2 Instance type, for example, using `charts/timescaledb-single/values/m5.large.example.yaml`:
    ```console
    helm upgrade --install my-release charts/timescaledb-single -f charts/timescaledb-single/values/m5.large.example.yaml
    ```

## Connecting

This Helm chart creates multiple [Service](https://kubernetes.io/docs/concepts/services-networking/service/)s,
2 of these are meant for connecting to the database.

If a Load Balancer has been configured with `enabled: True`, this Service is also exposed through a Load Balancer,
otherwise these services are [Headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)s,
which allows connections directly to indivudual pods using DNS.

### Connect to the primary
  ```console
  psql -h my-release
  ```

### Connect to a replica
  ```console
  psql -h my-release-replica -U postgres
  ```

### List the services
```console
RELEASE=my-release
kubectl get service -l release=${RELEASE}
```
In the below example you can see that
* `my-release` (the primary service) has a LoadBalancer associated with it which is exposed
    as `verylongname.example.com`.
* `my-release-replica` (the replica service) does not have a LoadBalancer, nor a ClusterIP, and therefore is a Headless Service
* `my-release-config` service is used for HA and cannot be used to connect to PostgreSQL.
```console
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP                PORT(S)          AGE
my-release           LoadBalancer   10.100.245.92   verylongname.example.com   5432:31271/TCP   5m49s
my-release-config    ClusterIP      None            <none>                     <none>           4m50s
my-release-replica   ClusterIP      None            <none>                     5432/TCP         5m49s
```

## Cleanup

Removing a deployment can be done by deleting a Helm deployment, however, removing the deployment does not remove
the Persistent Volume Claims (pvc) belonging to the cluster.

To fully purge a deployment in Kubernetes, you should do the following:
```sh
# Delete the Helm deployment
helm delete my-release
# Delete pvc
RELEASE=my-release
kubectl delete $(kubectl get pvc -l release=$RELEASE -o name)
```

### Optional: Delete the s3 backups
If you have configured backups, the S3 bucket will contain a Backup Stanza (configuration) and one or more backups. If the deployment name were to be reused
this will cause issues.

If you want to purge the backups, (re)move the s3 objects relating to your database, e.g. when using the [AWS Command Line Interface](https://aws.amazon.com/cli/):
```console
aws s3 rm s3://this_bucket_may_not_exist/default/my-release --recursive
```
Alternatively, you can use the [AWS Management Console](https://s3.console.aws.amazon.com/s3/) to delete those objects.

## Backups

### Create backups to S3
 the following items are required for you to enable creating backups to S3:

- an S3 bucket available for your backups
- an [IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)
- a [S3 Bucket Policy](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/add-bucket-policy.html) that allows the IAM user read and write access to (parts of) the S3 bucket
- access key that allows you to login as the IAM user

These configuration items should be part of the `RELEASE-pgbackrest` secret. Once you recreate this secret
with the correct configurations, you can enable the backup by setting `backup.enabled` to `true`, for example:

```yaml
# Filename: myvalues.yaml
backup:
  enabled: true
```
```
helm upgrade --install example -f myvalues.yaml charts/timescaledb-single
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

### Testing restore/recovery from inside the Kubernetes cluster
Every new pod that gets created needs to copy the PostgreSQL instance data. It will attempt do do this using the backup stored in the S3 bucket if available.
Once the restore is done, it will connect to the `master` and use streaming replication to catch up the last bits.

> **WARNING**: The following procedure updates a running Deployment

Assuming that you have deployed a 3-pod TimescaleDB, we can trigger the restore test by increasing the `replicaCount` from 3 to 4.
This should create a new pod, which we can inspect to verify that the restore was done correctly.

```sh
helm upgrade my-release -f myvalues.yaml charts/timescaledb-single --set replicaCount=4
# Wait a short while for the Pod to be scheduled and available
kubectl logs pod/my-release-timescaledb-3 -c timescaledb
```
The start of the restore should look like this:
```
2019-09-04 08:05:17,495 INFO: Lock owner: my-release-timescaledb-0; I am my-release-timescaledb-3
2019-09-04 08:05:17,518 INFO: trying to bootstrap from leader 'my-release-timescaledb-0'
INFO: restore command begin 2.16: --config=/home/postgres/pgdata/backup/pgbackrest.conf --delta [...]
INFO: restore backup set 20190904-071709F_20190904-071909I
INFO: restore file /home/postgres/pgdata/data/base/13101/1255 (656KB, 2%) checksum 70f74a12d5ed6226087bef7d49b384fd9aa9dc0b
[...]
```
If the restore has been successful, you should see the following in the logs at some point:
```
2019-09-04 08:05:23,613 INFO: replica has been created using pgbackrest
[...]
2019-09-04 08:05:24,704 INFO: does not have lock
2019-09-04 08:05:24,704 INFO: establishing a new patroni connection to the postgres cluster
2019-09-04 08:05:24,729 INFO: no action.  i am a secondary and i am following a leader
2019-09-04 08:05:33,780 INFO: Lock owner: my-release-timescaledb-0; I am my-release-timescaledb-3
```

> **WARNING**: The following procedure removes a running pod and its backup pvc

After testing the restore/recovery you may want to reduce the `replicaCount` back to its previous value.
To verify that we're not going to be causing a failover, we need to ensure the `master` is not running on the pod with
the highest number:
```console
kubectl get pod -l release=my-release -L role
```
```
NAME                       READY   STATUS    RESTARTS   AGE     ROLE
my-release-timescaledb-0   2/2     Running   0          19m     master
my-release-timescaledb-1   2/2     Running   0          18m     replica
my-release-timescaledb-2   2/2     Running   0          2m10s   replica
my-release-timescaledb-3   2/2     Running   0          96s     replica
```

If we reduce the `replicaCount` back to the original in this example, the `my-release-timescaledb-3` would be removed.

```
helm upgrade my-release -f myvalues.yaml charts/timescaledb-single --set replicaCount=3
```

You could also delete the `pvc` that was used by this pod:

```console
kubectl get pvc -l release=my-release
kubectl delete pvc/storage-volume-my-release-timescaledb-3
```

### Test restore/recovery from outside the Kubernetes cluster

> **WARNING** During the restore/recovery in this scenario you most likely will run into some issues,
> related to ownership of files, or paths that are configured incorrectly for your system.
> You should refer to the [PostgreSQL documentation](https://www.postgresql.org/docs/current/recovery-config.html)
> and [pgBackRest documentation](https://pgbackrest.org/user-guide.html#quickstart/perform-restore)
> to troubleshoot those issues.

In the event that you need to restore the database in an environment outside your Kubernetes cluster,
you should follow the following process:

- Create a configuration for pgBackRest
- Restore the database
- Review/reconfigure `recovery.conf` for your purpose
- Verify a successful restore

As the database backup is created using the `postgres` user, and `pgBackRest` will try to (re)set ownerships
of files it is probably best if you execute this process as a `postgres` user on a Linux system.

#### Create a pgBackRest Configuration file
Assuming we are going to do the restore in the /restore mountpoint, which is owned by `postgres`,
we could create the file `/restore/pgbackrest.conf`:
```ini
[global]
repo1-type=s3
repo1-s3-bucket=this_bucket_may_not_exist
repo1-path=/my-release-timescaledb/
repo1-s3-endpoint=s3.amazonaws.com
repo1-s3-region=us-east-2

[poddb]
pg1-path=/restore/data
pg1-port=5432
pg1-socket-path=/tmp/

recovery-option=standby_mode=on
recovery-option=recovery_target_timeline=latest
recovery-option=recovery_target_action=shutdown
```

#### Restore the database using pgBackRest
```console
export PGBACKREST_CONFIG="/restore/pgbackrest.conf"
pgbackrest restore --stanza=poddb
```

#### Verify a successful restore
You should be able to start the restored database using the correct binaries. This example uses PostgreSQL 11 binaries on a Debian based system
```console
/usr/lib/postgresql/11/bin/pg_ctl -D /restore/data --port=5430 start
psql -p 5430 -c 'SHOW cluster_name'
```
If the restore/recovery/starting was successful the output should be similar to the following:
```
 cluster_name
--------------
 my-release
(1 row)
```
### Verify Backup jobs

The backups are triggered by [CronJobs](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/).
The CronJob triggers a backup in the TimescaleDB Pod, which in turn instructs [pgBackRest](https://github.com/pgbackrest/pgbackrest) to create the backup.

To see the CronJobs and the Jobs that were created by these CronJobs, use something like the following:

```console
kubectl get cronjob,job -l release=my-release
```
```
NAME                                                     SCHEDULE     SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/my-release-timescaledb-full-weekly         27 * * * *   False     0        2m12s           8m9s
cronjob.batch/my-release-timescaledb-incremental-daily   28 * * * *   False     0        72s             8m9s

NAME                                                            COMPLETIONS   DURATION   AGE
job.batch/my-release-timescaledb-full-weekly-1567585620         1/1           3s         2m11s
job.batch/my-release-timescaledb-incremental-daily-1567585680   1/1           3s         71s
```
To inspect the logs of a specific job:
```console
kubectl logs job/my-release-timescaledb-full-weekly-1567585620
```
```json
{
    "age": 1.0,
    "duration": 1.0,
    "finished": null,
    "label": "20190904082702",
    "pgbackrest": {},
    "pid": 40,
    "returncode": null,
    "started": "2019-09-04T08:27:02+00:00",
    "status": "RUNNING"
}
```
As the CronJobs are only triggers they should complete within seconds. That is why in the above example both `returncode` and `finished` are `null`, they are not yet known.

To verify the actual backups we can use the `pgbackrest` command in any TimescaleDB pod belonging to that deployment,
for example:
```console
kubectl exec -ti $(kubectl get pod -l release=my-release,role=master) pgbackrest info
```
```
Defaulting container name to timescaledb.
Use 'kubectl describe pod/my-release-timescaledb-1 -n default' to see all of the containers in this pod.
stanza: poddb
    status: ok
    cipher: none

    db (current)
        wal archive min/max (11-1): 000000010000000000000002/000000010000000000000008

        full backup: 20190904-071153F
            timestamp start/stop: 2019-09-04 07:11:53 / 2019-09-04 07:12:08
            wal start/stop: 000000010000000000000002 / 000000010000000000000003
            database size: 24.4MB, backup size: 24.4MB
            repository size: 2.9MB, repository backup size: 2.9MB

        full backup: 20190904-071709F
            timestamp start/stop: 2019-09-04 07:17:09 / 2019-09-04 07:17:21
            wal start/stop: 000000010000000000000006 / 000000010000000000000006
            database size: 24.6MB, backup size: 24.6MB
            repository size: 2.9MB, repository backup size: 2.9MB

        incr backup: 20190904-071709F_20190904-071909I
            timestamp start/stop: 2019-09-04 07:19:09 / 2019-09-04 07:19:14
            wal start/stop: 000000010000000000000008 / 000000010000000000000008
            database size: 24.6MB, backup size: 8.2KB
            repository size: 2.9MB, repository backup size: 482B
            backup reference list: 20190904-071709F
```

## Callbacks
Patroni will trigger some callbacks on certain events. These are:

- on_reload
- on_restart
- on_role_change
- on_start
- on_stop

If you wish to have *your* script run after a certain event happens, you can do so by configuring
`callbacks.configMap` to point to a [ConfigMap](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.15/#configmap-v1-core). The value is templated so you can use `"{{ .Release.Name }}-patroni-callbacks"`
if you're deploying this chart in the same release with another chart that will create the config map.

This ConfigMap should exist before you install a chart. The data keys that match the event names will be executed
if the event happens. For convenience the `all` key will be executed at every event.

Every callback will be given 3 additional commandline arguments by Patroni, they are:

* action (e.g. `on_restart`, `on_stop`)
* role (`master`/`replica`)
* cluster\_name

For more information about callbacks, we refer you to the [Patroni Documentation](https://patroni.readthedocs.io/en/latest/SETTINGS.html#postgresql)

Inside these callbacks, you also have access to the environment variables of the pod, except the `PATRONI_` environment variables.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-patroni-callbacks
data:
  on_start: |
    #!/bin/bash
    echo "I just started"
  on_role_change: |
    #!/bin/bash
    curl http://${MYAPP}/
  all: |
    #!/bin/bash
    echo "$0 happened"
```

### Example: Register Patroni events in a table


*example-patroni-callbacks.yaml*
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-patroni-callbacks
data:
  all: |
    #!/bin/bash

    # This script should only run on the master instance, Patroni
    # passes on the role in the second parameter
    [ "$2" != "master" ] && exit 0

    psql --set ON_ERROR_STOP=1 \
          --set events_table=${EVENTS_TABLE} \
          --set hostname=$(hostname) \
          --set event=$1 <<__SQL__
      -- After a promote it may take a short while before our transaction actually
      -- allows us to write therefore we sleep a short while if we're still in recovery
      SELECT pg_sleep(3)
      WHERE  pg_is_in_recovery();

      CREATE TABLE IF NOT EXISTS :"events_table"(
        happened timestamptz,
        event text,
        pod text
      );

      INSERT INTO :"events_table"
      VALUES (now(), :'event', :'hostname');
    __SQL__
```

*myvalues.yaml*
```yaml
callbacks:
  configMap: example-patroni-callbacks

env:
  - name: EVENTS_TABLE
    value: patroni_events
```

```console
kubectl apply -f example-patroni-callbacks.yaml
helm upgrade --install example ./charts/timescaledb-single -f myvalues.yaml
```

After waiting a while, and having done some failovers, inspecting the resulting the table shows the following:
```console
kubectl exec \
    $(kubectl get pod -o name -l cluster-name=example,role=master) \
    -ti -- psql -c 'table patroni_events';
```
```
           happened            |     event      |          pod
-------------------------------+----------------+-----------------------
 2019-11-07 21:11:07.817848+00 | on_start       | example-timescaledb-0
 2019-11-07 21:11:36.200115+00 | on_role_change | example-timescaledb-0
 2019-11-07 21:12:39.099195+00 | on_role_change | example-timescaledb-1
 2019-11-07 21:15:06.596093+00 | on_role_change | example-timescaledb-0
 2019-11-07 21:15:12.062173+00 | on_role_change | example-timescaledb-1
 2019-11-07 21:15:22.736801+00 | on_role_change | example-timescaledb-0
 2019-11-07 21:15:41.676756+00 | on_role_change | example-timescaledb-2
(7 rows)

```

## Troubleshooting


### List Resources
All the resources that are deployed can be listed by providing the filter `-l release=my-release`.
By adding the `role` label in the output, we get some more insight into the deployment, as Patroni adds a `role=master` label to the elected master and set the label
to `role=replica` for all replicas.

The `<release-name>` endpoint is always pointing to the Patroni elected master.

```console
RELEASE=my-release
kubectl get all,endpoints,pvc -l release=${RELEASE} -L role
```
The output should be similar to the below output:
```console
NAME                           READY   STATUS    RESTARTS   AGE     ROLE
pod/my-release-timescaledb-0   1/1     Running   0          2m51s   master
pod/my-release-timescaledb-1   1/1     Running   0          111s    replica
pod/my-release-timescaledb-2   1/1     Running   0          67s     replica

NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP                PORT(S)          AGE     ROLE
service/my-release           LoadBalancer   10.100.245.92   verylongname.example.com   5432:31271/TCP   2m51s
service/my-release-config    ClusterIP      None            <none>                     <none>           112s
service/my-release-replica   ClusterIP      None            <none>                     5432/TCP         2m51s

NAME                                      READY   AGE     ROLE
statefulset.apps/my-release-timescaledb   3/3     2m51s

NAME                               ENDPOINTS                               AGE     ROLE
endpoints/my-release               192.168.6.0:5432                        110s
endpoints/my-release-config        <none>                                  113s
endpoints/my-release-replica       192.168.53.62:5432,192.168.67.91:5432   2m52s
endpoints/my-release-timescaledb   <none>                                  2m52s

NAME                                                            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE     ROLE
persistentvolumeclaim/storage-volume-my-release-timescaledb-0   Bound    pvc-43586bd8-0080-11ea-a2fb-06e2eca748a8   2Gi        RWO            gp2            2m52s
persistentvolumeclaim/storage-volume-my-release-timescaledb-1   Bound    pvc-66e6bc31-0080-11ea-a2fb-06e2eca748a8   2Gi        RWO            gp2            112s
persistentvolumeclaim/storage-volume-my-release-timescaledb-2   Bound    pvc-814667a0-0080-11ea-a2fb-06e2eca748a8   2Gi        RWO            gp2            68s
persistentvolumeclaim/wal-volume-my-release-timescaledb-0       Bound    pvc-43592ab2-0080-11ea-a2fb-06e2eca748a8   1Gi        RWO            gp2            2m52s
persistentvolumeclaim/wal-volume-my-release-timescaledb-1       Bound    pvc-66e824be-0080-11ea-a2fb-06e2eca748a8   1Gi        RWO            gp2            112s
persistentvolumeclaim/wal-volume-my-release-timescaledb-2       Bound    pvc-81479676-0080-11ea-a2fb-06e2eca748a8   1Gi        RWO            gp2            68s
```

### Investigate TimescaleDB logs

The logs for the current `master` of TimescaleDB can be accessed as follows:

```console
RELEASE=my-release
kubectl logs $(kubectl get pod -o name -l release=$RELEASE,role=master) -c timescaledb
```

### Switching a LoadBalancer type
If you want to switch a service from `ClusterIP` to `LoadBalancer`, some extra work may be required.

When using Helm 3 when trying to change a value, Helm will try to patch the kubernetes objects involved.
However, due to some Kubernetes issues ([#221](https://github.com/kubernetes/kubectl/issues/221), [#11237](https://github.com/kubernetes/kubernetes/issues/11237)), this patching strategy does not always work.


```console
$ helm upgrade --install example ./charts/timescaledb-single/ --set replicaLoadBalancer.enabled=True
Error: UPGRADE FAILED: cannot patch "example-replica" with kind Service: Service "example-replica" is invalid: spec.clusterIP: Invalid value: "": field is immutable
```

To get around this issue, we can delete the service before we switch the type of the LoadBalancer.

> **WARNING**: This will cause **downtime** for every application that is currently using this specific service.
> Every client that is currently connected to this specific service will be disconnected and will only
> be able to reconnect if the new service has been created and is fully functional.

```console
$ kubectl delete service/example-replica
service "example-replica" deleted
$ helm upgrade --install example ./charts/timescaledb-single/ --set replicaLoadBalancer.enabled=True
Release "example" has been upgraded. Happy Helming!
```

## Common Issues

### `Could not resize shared memory segment "/PostgreSQL.1521128888" to 8388608 bytes:`

This error message occurs if you're running out of space on the `/dev/shm` Volume.
By default, Kubernetes only provides 64MB of space for `/dev/shm`, however, PostgreSQL may
require (a lot) more space depending on the work load.

This memory however is only used for the work memory for parallel query workers.
To mitigate this, you could:

- reduce [`work_mem`](https://www.postgresql.org/docs/current/runtime-config-resource.html#GUC-WORK-MEM)
- reduce [`max_parallel_workers`](https://www.postgresql.org/docs/current/runtime-config-resource.html#GUC-MAX-PARALLEL-WORKERS)

Alternatively, you could enable the mounting of Memory to `/dev/shm`, by enabling this feature in `values.yaml`:

```yaml
sharedMemory:
  useMount: true
```

For some further background:
- [Support Posix Shared Memory across containers in a pod](https://github.com/kubernetes/kubernetes/issues/28272)
- [Increase POSIX Shared Memory for Kubernetes](https://docs.okd.io/latest/dev_guide/shared_memory.html)

### `MountVolume.SetUp failed for volume "<volume name>": secret "<release>-secret" not found`

This error points to missing Secrets. Since release 0.6.0 the Secrets are no longer part of this Helm Chart and should
be managed separately.

* When upgrading a 0.5 deployment to 0.6: [Upgrade Guide](upgrade-guide.md#migrate-the-secrets)
* When creating a new deployment, or if the old Secrets are no longer available: [Create the Secrets](#creating-the-secrets)
