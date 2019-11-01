<!---
This file and its contents are licensed under the Apache License 2.0.
Please see the included NOTICE for copyright information and LICENSE for a copy of the license.
-->

# TimescaleDB Single Administrator Guide

##### Table of Contents
- [Configuration](#configuration)
- [Backups](#backups)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)

## Configuration
The following table lists the configurable parameters of the TimescaleDB Helm chart and their default values.

|       Parameter                   |           Description                       |                         Default                     |
|-----------------------------------|---------------------------------------------|-----------------------------------------------------|
| `nameOverride`                    | Override the name of the chart              | `timescaledb`                                       |
| `clusterName`                     | Override the name of the PostgreSQL cluster | Equal to the Helm release name                      |
| `fullnameOverride`                | Override the fullname of the chart          | `nil`                                               |
| `replicaCount`                    | Amount of pods to spawn                     | `3`                                                 |
| `image.repository`                | The image to pull                           | `timescaledev/timescaledb-ha`                       |
| `image.tag`                       | The version of the image to pull            | `pg11-ts1.4`                                        |
| `image.pullPolicy`                | The pull policy                             | `IfNotPresent`                                      |
| `credentials`                     | A mapping of usernames/passwords            | A postgres, standby and admin user                  |
| `tls.cert`                        | The public key of the SSL certificate for PostgreSQL | empty (a self-signed certificate will be generated) |
| `tls.key`                         | The private key of the SSL Certificate for PostgreSQL | empty                                     |
| `backup.enable`                   | Schedule backups to occur                   | `false`                                             |
| `backup.pgBackRest`               | [pgBackRest configuration](https://github.com/timescale/timescaledb-kubernetes/blob/master/charts/timescaledb-single/values.yaml)     | Working defaults |
| `backup.jobs`                     | A list of backup schedules and types        | 1 full weekly backup, 1 incremental daily backup    |
| `env`                             | Extra custom environment variables          | `{}`                                                |
| `patroni`                         | Specify your specific [Patroni Configuration](https://patroni.readthedocs.io/en/latest/SETTINGS.html) | A full Patroni configuration |
| `resources`                       | Any resources you wish to assign to the pod | `{}`                                                |
| `nodeSelector`                    | Node label to use for scheduling            | `{}`                                                |
| `tolerations`                     | List of node taints to tolerate             | `[]`                                                |
| `affinityTemplate`                | A template string to use to generate the affinity settings | Anti-affinity preferred on hostname and (availability) zone |
| `affinity`                        | Affinity settings. Overrides `affinityTemplate` if set. | `{}`                                    |
| `schedulerName`                   | Alternate scheduler name                    | `nil`                                               |
| `loadBalancer.annotations`        | Pass on annotations to the Load Balancer    | An AWS ELB annotation to increase the idle timeout  |
| `persistentVolumes.data.enabled`  | If enabled, use a Persistent Data Volume    | `true`                                              |
| `persistentVolumes.data.mountPath`| Persistent Data Volume mount root path      | `/var/lib/postgresql/`                              |
| `persistentVolumes.wal.enabled`   | If enabled, use a Persistent Wal Volume. If disabled, WAL will be on the Data Volume | `true`     |
| `persistentVolumes.wal.mountPath` | Persistent Wal Volume mount root path       | `/var/lib/postgresql/wal/`                          |
| `persistentVolumes.<name>.accessModes` | Persistent Volume access modes         | `[ReadWriteOnce]`                                   |
| `persistentVolumes.<name>.annotations` | Annotations for Persistent Volume Claim| `{}`                                                |
| `persistentVolumes.<name>.size`   | Persistent Volume size                      | `2Gi`                                               |
| `persistentVolumes.<name>.storageClass`| Persistent Volume Storage Class        | `volume.alpha.kubernetes.io/storage-class: default` |
| `persistentVolumes.<name>.subPath`| Subdirectory of Persistent Volume to mount  | `""`                                                |
| `rbac.create`                     | Create required role and rolebindings       | `true`                                              |
| `serviceAccount.create`           | If true, create a new service account       | `true`                                              |
| `serviceAccount.name`             | Service account to be used. If not set and `serviceAccount.create` is `true`, a name is generated using the fullname template | `nil` |

### Examples
- Override value using commandline parameters
    ```console
    helm upgrade --install my-release charts/timescaledb-single --set image.tag=pg11.5-ts1.4.2 --set image.pullPolicy=Always
    ```
- Override values using `myvalues.yaml`
    ```yaml
    # Filename: myvalues.yaml
    image:
      tag: pg11.5-ts1.4.2
      pullPolicy: Always
    patroni:
      postgresql:
        parameters:
          checkpoint_completion_target: 32MB
    ```
    ```console
    helm upgrade --install my-release charts/timescaledb-single -f myvalues.yaml
    ```
- Use an example values file to match an AWS EC2 Instance type, for example, using `charts/timescaledb-single/values/m5.large.example.yaml`:
    ```console
    helm upgrade --install my-release charts/timescaledb-single -f charts/timescaledb-single/values/m5.large.example.yaml
    ```

## Cleanup

Removing a deployment can be done by deleting a Helm deployment, however, removing the deployment does not remove:
- the Persistent Volume Claims (pvc) belonging to the cluster
- or the headless service that is used by Patroni for its configuration

To fully purge a deployment in Kubernetes, you should do the following:
```console
# Delete the Helm deployment
helm delete my-release
# Delete pvc and the headless Patroni service and the endpoints
RELEASE=my-release
kubectl delete $(kubectl get pvc,service,endpoints -l release=$RELEASE -o name)
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

If you (re)deploy your database with this configuration snippet in the values file, the backup should start working.

```yaml
# Filename: myvalues.yaml
backup:
  enable: True
    pgBackRest:
      repo1-s3-bucket: this_bucket_may_not_exist
      repo1-s3-key: 9E1R2CUZBXJVYSBYRWTB
      repo1-s3-key-secret: 5CrhvJD08bp9emxI+D48GXfDdtl823nlSRRv7dmB
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

```console
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
repo1-s3-key=9E1R2CUZBXJVYSBYRWTB
repo1-s3-key-secret=5CrhvJD08bp9emxI+D48GXfDdtl823nlSRRv7dmB
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
pod/my-release-timescaledb-0   1/1     Running   0          3m57s   replica
pod/my-release-timescaledb-1   1/1     Running   0          3m37s   master
pod/my-release-timescaledb-2   1/1     Running   0          3m26s   replica

NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP                PORT(S)          AGE     ROLE
service/my-release          LoadBalancer   10.100.13.250   verylongname.example.com   5432:31595/TCP   3m59s
service/my-release-config   ClusterIP      None            <none>                     <none>           20m

NAME                                      READY   AGE   ROLE
statefulset.apps/my-release-timescaledb   3/3     4m

NAME                               ENDPOINTS             AGE     ROLE
endpoints/my-release               192.168.66.154:5432   3m38s
endpoints/my-release-config        <none>                20m
endpoints/my-release-timescaledb   <none>                4m

NAME                                                            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE     ROLE
persistentvolumeclaim/storage-volume-my-release-timescaledb-0   Bound    pvc-5ea02576-ef44-11e9-83cf-0648583d35f4   1Gi        RWO            gp2            20m     
persistentvolumeclaim/storage-volume-my-release-timescaledb-1   Bound    pvc-69abba64-ef44-11e9-83cf-0648583d35f4   1Gi        RWO            gp2            20m     
persistentvolumeclaim/storage-volume-my-release-timescaledb-2   Bound    pvc-757503a5-ef44-11e9-83cf-0648583d35f4   1Gi        RWO            gp2            19m     
persistentvolumeclaim/storage-volume-my-release-timescaledb-3   Bound    pvc-44c31a41-ef46-11e9-83cf-0648583d35f4   1Gi        RWO            gp2            6m51s   
```

### Investigate TimescaleDB logs

The logs for the current `master` of TimescaleDB can be accessed as follows:

```console
RELEASE=my-release
kubectl logs $(kubectl get pod -o name -l release=$RELEASE,role=master) -c timescaledb
```
