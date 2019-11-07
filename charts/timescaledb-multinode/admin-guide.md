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
| `fullnameOverride`                | Override the fullname of the chart          | `nil`                                               |
| `replicaCount`                    | Amount of pods to spawn                     | `3`                                                 |
| `image.repository`                | The image to pull                           | `timescaledev/timescaledb`                          |
| `image.tag`                       | The version of the image to pull            | `v0.2.2-pg11-multinode`                             |
| `image.pullPolicy`                | The pull policy                             | `IfNotPresent`                                      |
| `credentials.accessNode.superuser`| Password of the superuser for the Access Node | `tea`                                             |
| `credentials.dataNode.superuser`  | Password of the superuser for the Data Nodes  | `coffee`                                          |
| `env`                             | Extra custom environment variables, expressed as [EnvVar](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.16/#envvarsource-v1-core) | `PGDATA` and some language settings |
| `resources`                       | Any resources you wish to assign to the pod | `{}`                                                |
| `nodeSelector`                    | Node label to use for scheduling            | `{}`                                                |
| `tolerations`                     | List of node taints to tolerate             | `[]`                                                |
| `affinityTemplate`                | A template string to use to generate the affinity settings | Anti-affinity preferred on hostname  |
| `affinity`                        | Affinity settings. Overrides `affinityTemplate` if set. | `{}`                                    |
| `postgresql.databases`            | List of databases to automatically create a multinode setup for | `["postgres", "example"]`       |
| `postgresql.parameters`           | [PostgreSQL parameters](https://www.postgresql.org/docs/current/config-setting.html#CONFIG-SETTING-CONFIGURATION-FILE)) | Some required and preferred settings |
| `schedulerName`                   | Alternate scheduler name                    | `nil`                                               |
| `persistentVolume.accessModes`    | Persistent Volume access modes              | `[ReadWriteOnce]`                                   |
| `persistentVolume.annotations`    | Annotations for Persistent Volume Claim`    | `{}`                                                |
| `persistentVolume.mountPath`      | Persistent Volume mount root path           | `/var/lib/postgresql`                               |
| `persistentVolume.size`           | Persistent Volume size                      | `5Gi`                                               |
| `persistentVolume.storageClass`   | Persistent Volume Storage Class             | `volume.alpha.kubernetes.io/storage-class: default` |
| `persistentVolume.subPath`        | Subdirectory of Persistent Volume to mount  | `""`                                                |
| `rbac.create`                     | Create required role and rolebindings       | `true`                                              |
| `serviceAccount.create`           | If true, create a new service account       | `true`                                              |
| `serviceAccount.name`             | Service account to be used. If not set and `serviceAccount.create` is `true`, a name is generated using the fullname template | `nil` |

### Examples
- Override value using commandline parameters
    ```console
    helm upgrade --install my-release . --set image.tag=v0.2.3-pg11-multinode --set image.pullPolicy=Always
    ```
- Override values using `myvalues.yaml`
    ```yaml
    # Filename: myvalues.yaml
    image:
      tag: v0.2.3-pg11
      pullPolicy: Always
    postgresql:
      databases:
      - postgres
      - proddb
      parameters:
        checkpoint_completion_target: 32MB
        work_mem: 16MB
        shared_buffers: 512MB
    ```
    ```console
    helm upgrade --install my-release . -f myvalues.yaml
    ```

## Cleanup

Removing a deployment can be done by deleting a Helm deployment, however, removing the deployment does not remove:
- the Persistent Volume Claims (pvc) belonging to the cluster

To fully purge a deployment in Kubernetes, you should do the following:
```console
# Delete the Helm deployment
helm delete my-release
# Delete pvc and the headless Patroni service
kubectl delete $(kubectl get pvc -l release=my-release -o name)
```

## Troubleshooting


### List Resources
All the resources that are deployed can be listed by providing the filter `-l release=my-release`.

```console
kubectl get all -l release=my-release
```
The output should be similar to the below output:
```console
NAME                                  READY   STATUS      RESTARTS   AGE
pod/my-release-timescaledb-access-0   1/1     Running     0          11m
pod/my-release-timescaledb-data-0     1/1     Running     0          11m
pod/my-release-timescaledb-data-1     1/1     Running     0          11m
pod/my-release-timescaledb-data-2     1/1     Running     0          11m


NAME                                  TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/my-release-timescaledb        LoadBalancer   10.152.183.60   <pending>     5432:31819/TCP   11m
service/my-release-timescaledb-data   ClusterIP      None            <none>        5432/TCP         11m

NAME                                             READY   AGE
statefulset.apps/my-release-timescaledb-access   1/1     11m
statefulset.apps/my-release-timescaledb-data     3/3     11m
```

> **INFO** When listing resources within minutes of deploying a new Helm chart, you may see a list of jobs and its pods;
these jobs are there to create the database, and to attach the data nodes to the access node. There will be quite a few,
but these should disappear within minutes after successful deployment.

### Investigate TimescaleDB logs

The logs for the Access Node of TimescaleDB can be accessed as follows:

```console
kubectl logs $(kubectl get pod -l release=my-release,timescaleNodeType=access) timescaledb
```
