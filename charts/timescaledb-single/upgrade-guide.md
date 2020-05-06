# Upgrading from 0.5.x to 0.6.0

Starting with version 0.6.0 the helm chart no longer creates the required 
secrets for cluster configuration internally. As a result, the schema of the
`values` has been changed. This document's other sections have been updated to 
reflect these changes, and the steps you can take to generate the required 
secrets outside of the deployment of the chart, see: [Install](./README.md#installing) 
and [Configuration](./admin-guide.md#creating-the-secrets).

For those of you that have existing deployments of version 0.5.x here's what you
need to do. 

## 1. Migrate the secrets

If you deployed 0.5.x and you used the secrets created by the chart, you will 
need to edit them. 
You can get the secrets with: 
```sh
kubectl get secrets -l release=<my_release>
```
You will see at least two secrets:
```
NAME                                   TYPE                DATA   AGE
<my_release>-timescaledb-certificate   kubernetes.io/tls   2      20d
<my_release>-timescaledb-passwords     Opaque              6      20d
<my_release>-timescaledb-pgbackrest    Opaque              4      20d
```
The third will be there if you had backups enabled. (If yes, check out 
[Upgrading backups](#upgrading-backups-(if-enabled)) after finishing
this step and step [2.](#2.-update-your-values.yaml-file))

You need now to edit each of the secrets so you can re-use them after the upgrade.
Without editing them. 

1. Edit `<my_release>-timescaledb-certificate`
   1. Open up the secret definition in your default editor:
      ```sh
      kubectl edit secret <my_release>-timescaledb-certificate
      ```
      It will open up something like this:
      ```yaml
      # Edit the object below. Lines beginning with a '#' will be ignored, an empty file will abort the edit. If an error occurs while saving this file will be reopened
      #
      apiVersion: v1
      data:
        tls.crt: your existing tls cert is here
        tls.key: your existing tls key is here
      kind: Secret
      metadata:
        annotations:
          meta.helm.sh/release-name: <my_release>
          meta.helm.sh/release-namespace: default
        labels:
          app: <my_release>-timescaledb
          app.kubernetes.io/managed-by: Helm
          chart: timescaledb-single-0.5.5
          heritage: Helm
          release: c
      ```
   2. Add the `helm.sh/resource-policy: keep` annotation, so 
   Helm will not delete the secret as they are no longer part of the release.
   3. save and exit. 
   Kubernetes will apply the changes to the resource

2. Edit the `<my_release>-timescaledb-passwords` Secret
   1. `kubectl edit secret <my_release>-timescaledb-passwords` (see 1.1)
   2. Add the `helm.sh/resource-policy: keep` annotation
   3. Edit the keys for the different users in `data:`.
      The `data:` section will look 
      like this:
      ```yaml
      data:
        admin: base64encodedPassForAdminUser
        postgres: base64encodedPassForSuperUser
        standby: base64encodedPassForReplicationUser
      ```
      In order for v0.6.0 to deploy, the keys for the passwords need to be changed to:
      ```yaml
      data:
        PATRONI_REPLICATION_PASSWORD: base64encodedPassForAdminUser
        PATRONI_SUPERUSER_PASSWORD: base64encodedPassForSuperUser
        PATRONI_admin_PASSWORD: base64encodedPassForReplicationUser
      ```
      > **NOTE:** The values don't need to change, just the keys
   4. Save and exit

## 2. Update your values.yaml file

If you don't have a local values file to override defaults, you should 
create it.
1. Set the values for `secretNames.credentials` and `secretNames.certificate` 
to the names of the existing secrets
   ```yaml
   # inside my_values.yaml
   secretNames:
     credentials: <my_release>-timescaledb-passwords
     certificate: <my_release>-timescaledb-certificate
   ```
   
2. Remove the `credentials` and `tls` sections if you have them overridden
from the previous release.

## 3. Upgrading backups (if enabled)
The `<my_release>-timescaledb-pgbackrest` Secret needs to change the most. 
Instead of keeping the complete `pgbackrest.conf` file it now only keeps 
track of the pgBackRest environment variables.

**First**: edit the `<my_release>-timescaledb-pgbackrest` Secret:
1. Decode the secret so you can get the values for the new environment variables
   ```sh
   kubectl get secret \
     <my_release>-timescaledb-pgbackrest \
     -o jsonpath="{.data.pgbackrest\.conf}" | \
     base64 --decode ; echo
   ```
   It will print out something like:
   ```conf
   [global]
   compress-level=3
   process-max=4
   repo1-cipher-type=none
   repo1-path=/default/e/
   repo1-retention-diff=2
   repo1-retention-full=2
   repo1-s3-bucket=my_example_s3_bucket_for_backups
   repo1-s3-endpoint=s3.amazonaws.com
   repo1-s3-key=examplekeyid
   repo1-s3-key-secret=examplesecret+D48GXfDdtl823nlSRRv7dmB
   repo1-s3-region=us-east-2
   repo1-type=s3
   spool-path=/var/run/postgresql
   start-fast=y
   
   [poddb]
   pg1-port=5432
   pg1-host-user=postgres
   pg1-path=/var/lib/postgresql/data
   pg1-socket-path=/var/run/postgresql
   
   recovery-option=standby_mode=on
   recovery-option=recovery_target_timeline=latest
   recovery-option=recovery_target_action=shutdown
   
   link-all=y
   
   [global:archive-push]
   
   [global:archive-get]
   ```
2. Store this temporarily in a `pgbackrest.conf.tmp`
3. `kubectl edit secret <my_release>-timescaledb-pgbackrest`
4. Add the `helm.sh/resource-policy: keep` annotation
5. Delete the `pgbackrest.conf` item from `data` and add the following:
   ```yaml
   data:
      PGBACKREST_REPO1_S3_BUCKET: my_example_s3_bucket_for_backups
      PGBACKREST_REPO1_S3_ENDPOINT: s3.amazonaws.com
      PGBACKREST_REPO1_S3_KEY: examplekeyid
      PGBACKREST_REPO1_S3_KEY_SECRET: examplesecret+D48GXfDdtl823nlSRRv7dmB
      PGBACKREST_REPO1_S3_REGION: us-east-2
   ```
   Where the values for each of the ENV vars will be taken from the `pgbackrest.conf.tmp`
   file you stored in step 3.2 (repo1-s3-bucket became PGBACKREST_REPO1_S3_BUCKET and so on)
6. Save and exit

**Second**: Add the rest of the items from `pgbackrest.conf.tmp` to `backup.pgBackRest` in your values file 
> **Note**:make sure you don't add the values you just placed in the Secret in step First.5)
For more details about pgbackrest.conf see the [admin-guide](./admin-guide.md#pgBackRest)

## 4. Helm upgrade
You should now be ready to upgrade with:
```sh
helm upgrade <my_release> \
  --version=0.6.0 \
  timescale/timescaledb-single
```
As always it is a good practice to do a dry run before doing the actual install:
```sh
helm upgrade <my_release> \
  --version=0.6.0 \
  --dry-run \
  timescale/timescaledb-single
```

## 5. (Optional, but recommended) Remove helm annotations from Secrets

When you were editing the secrets you may have noticed that they were
annotated with: 
```yaml
meta.helm.sh/release-name: <my_release>
meta.helm.sh/release-namespace: default
```
and labeled with:
```yaml
labels:
  app.kubernetes.io/managed-by: Helm
  chart: timescaledb-single-0.5.5
  heritage: Helm
  release: <my_release>
```
You should edit the secrets again now and remove these annotations and
labels because these objects are no longer managed by Helm.

