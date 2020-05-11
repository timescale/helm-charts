# Upgrade your deployment

Before you upgrade your deployment, you should ensure you have
followed the version specific upgrade guides.

##### Upgrade guides
- [0.5 to 0.6](#upgrading-from-05x-to-06x)
- [0.4 to 0.5](#upgrading-from-04x-to-05x)

After you have followed the upgrade guide you should be able to upgrade your deployment as follows:

> WARNING: Most upgrades will involve restarting the pods. Patroni will failover the master if this
> happens, so downtime is minimal, but there is some disruption.
```sh
helm upgrade --install my-release ./charts/timescaledb-single -f values/my-release.yaml
```


# Upgrading from 0.5 to 0.6

Starting with version 0.6.0 the helm chart no longer creates the required
secrets for cluster configuration internally. As a result, the schema of the
`values` has been changed. This document's other sections have been updated to
reflect these changes, and the steps you can take to generate the required
secrets outside of the deployment of the chart, see: [Install](./README.md#installing)
and [Configuration](./admin-guide.md#creating-the-secrets).

For those of you that have existing deployments of version 0.5 here's what you
need to do.


## Migrate the Secrets
To aid in the migration of the secrets, you can execute the following commands.
This can safely be done a long time before the actual upgrade, these Secrets can
coexist just fine.

Afterwards, you will have 2 sets of Secrets, those belonging to the 0.5 release,
and Secrets that are stand-alone. Once you upgrade, the Secrets that are stand-alone
remain.

```sh
echo "What is the name of the deployment you wish to migrate?"
read TSRELEASE

(
  set -e

  echo
  echo "Checking if the release can be found ..."
  kubectl get endpoints/${TSRELEASE} > /dev/null

  echo
  echo "Migrating the credentials"
  K8SSECRET="secret/${TSRELEASE}-timescaledb-passwords"
  kubectl apply -f - << __EOT__
apiVersion: v1
kind: Secret
metadata:
  labels:
    app: ${TSRELEASE}-timescaledb
    cluster-name: ${TSRELEASE}
  name: ${TSRELEASE}-credentials
data:
  PATRONI_REPLICATION_PASSWORD: |
    $(kubectl get ${K8SSECRET} -o jsonpath="{ .data.standby }")
  PATRONI_SUPERUSER_PASSWORD: |
    $(kubectl get ${K8SSECRET} -o jsonpath="{ .data.postgres }")
  PATRONI_admin_PASSWORD: |
    $(kubectl get ${K8SSECRET} -o jsonpath="{ .data.admin }")
__EOT__

  echo
  echo "Migrating the certificate"
  K8SSECRET="secret/${TSRELEASE}-timescaledb-certificate"
  kubectl apply -f - << __EOT__
apiVersion: v1
kind: Secret
metadata:
  labels:
    app: ${TSRELEASE}-timescaledb
    cluster-name: ${TSRELEASE}
  name: ${TSRELEASE}-certificate
type: kubernetes.io/tls
data:
  tls.crt: |
    $(kubectl get ${K8SSECRET} -o 'go-template={{index .data "tls.crt"}}')
  tls.key: |
    $(kubectl get ${K8SSECRET} -o 'go-template={{index .data "tls.key"}}')
__EOT__

  kubectl get secret/${TSRELEASE}-timescaledb-pgbackrest &>/dev/null || exit 0
  echo
  echo "Migrating backup configuration"
  kubectl apply -f - << __EOT__
apiVersion: v1
kind: Secret
metadata:
  labels:
    app: ${TSRELEASE}-timescaledb
    cluster-name: ${TSRELEASE}
  name: ${TSRELEASE}-pgbackrest
data: {}
__EOT__

  GOTEMPLATE="go-template='{{ index .data \"pgbackrest.conf\" | base64decode }}'"
  K8SSECRET=secret/${TSRELEASE}-pgbackrest
  for line in $(kubectl get secret/${TSRELEASE}-timescaledb-pgbackrest -o "${GOTEMPLATE}")
  do
      # This transforms s3 related backup configuration into individual items that
      # are exposed as environment variables in the container,
      # for example, the line 'repo1-s3-region=us-east-2' becomes the following item
      # in the Secret: `PGBACKREST_REPO1_S3_REGION: dXMtZWFzdC0yCg==`
      case $line in
          *"-s3-"*)
              key="$(echo "${line%=*}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
              value="$(echo "${line##*=}" | base64)"
              kubectl patch ${K8SSECRET} --patch="data: {PGBACKREST_$key: $value}"
              ;;
      esac
  done
)
```

You should now remove the `credentials` and `tls` sections from the `values.yaml`, and remove
any secrets you may have specified in under the `backup.pgBackRest` setting.

> **Note**:make sure you don't add the values you just placed in the Secret in step First.5)
For more details about pgbackrest.conf see the [admin-guide](./admin-guide.md#pgBackRest)

# Upgrading from 0.4 to 0.5

## Delete the config Service
```sh
echo "What is the name of the deployment you wish to migrate?"
read TSRELEASE

kubectl delete service/${TSRELEASE}-config
```
You should also follow the steps to upgrade to 0.6.0: [Upgrading from 0.5 to 0.6](#upgrading-from-05-to-06)
