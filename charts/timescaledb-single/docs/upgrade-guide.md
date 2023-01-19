# Upgrade your deployment

Before you upgrade your deployment, you should ensure you have
followed the version specific upgrade guides.

##### Upgrade guides
- [Upgrade your deployment](#upgrade-your-deployment)
        - [Upgrade guides](#upgrade-guides)
- [Upgrading to 0.20](#upgrading-to-020)
- [Upgrading to 0.16](#upgrading-to-016)
- [Upgrading from 0.10 to 0.11](#upgrading-from-010-to-011)
- [Upgrading from 0.9 to 0.10](#upgrading-from-09-to-010)
- [Upgrading from 0.8 to 0.9](#upgrading-from-08-to-09)
- [Upgrading from 0.7 to 0.8](#upgrading-from-07-to-08)
- [Upgrading from 0.6 to 0.7](#upgrading-from-06-to-07)
- [Upgrading from 0.5 to 0.6](#upgrading-from-05-to-06)
  - [Migrate the Secrets](#migrate-the-secrets)
- [Upgrading from 0.4 to 0.5](#upgrading-from-04-to-05)
  - [Delete the config Service](#delete-the-config-service)

After you have followed the upgrade guide you should be able to upgrade your deployment as follows:

> WARNING: Most upgrades will involve restarting the pods. Patroni will failover the master if this
> happens, so downtime is minimal, but there is some disruption.
```sh
helm upgrade --install my-release ./charts/timescaledb-single -f values/my-release.yaml
```

# Upgrading to 0.28

This release removes `affinityTemplate` field and removes default settings. If you were using `affinityTemplate` field, please migrate your values to `affinity` field.

Removal of default values shouldn't affect topology spread as helm chart defaults are also a kubernetes default behavior since version 1.24 (as defined in [`topologySpreadConstrains` doc](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#internal-default-constraints)). This behavior was also enabled in kubernetes 1.20+ as kube-scheduler beta option.

However if you need to keep the default behavior, please add the similar value your `affinity` field:

```yaml
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: "kubernetes.io/hostname"
        labelSelector:
          matchLabels:
            app: '{{ template "timescaledb.fullname" . }}'
            release: "{{ .Release.Name | quote }}"
            cluster-name: '{{ template "clusterName" . }}'
    - weight: 50
      podAffinityTerm:
        topologyKey: failure-domain.beta.kubernetes.io/zone
        labelSelector:
          matchLabels:
            app: {{ template "timescaledb.fullname" . }}
            release: {{ .Release.Name | quote }}
            cluster-name: {{ template "clusterName" . }}
```

If you need to keep this rule, please add it to your `affinity` field.

# Upgrading to 0.27

This release removes `nameOverride` field from `values.yaml` in favor of `fullnameOverride`. If you were using `nameOverride` field, please update your values file to use the new field.

# Upgrading to 0.25

This release removes an experimental feature of automated prevention for full WAL volume (`fullWalPrevention`). Going forward we recommend using monitoring and alerting to prevent such scenario from happening.

# Upgrading to 0.20

In 0.10.0 release we announced deprecation of `loadBalancer` and `replicaLoadBalancer` fields. In this release we are removing those deprecated fields in favor of `service.primary` and `serivce.replica`. If you were still using deprecated fields, please update your values file to use the new fields. This change also makes creation of `LoadBalancer` Service an explicit action that needs to be enabled by user.

# Upgrading to 0.16

Gethering metrics from postgres-exporter was changed and this helm chart no longer creates a Service dedicated to metrics exposition. It is advised to use `pod` role when using prometheus `kubernetes_sd_config`. Additionally `ServiceMonitor` object was deprecated and replaced with `PodMonitor`. Due to this change `.values.serviceMonitor` option was renamed to `.values.podMonitor`.

# Upgrading from 0.10 to 0.11

Handndling secrets was changed to remove kustomize wrapper. `unsafe_credentials` was removed and helm now generates secrets on first run unless they are provided in `secrets` map. To upgrade from previous chart version it is necessary to move secrets from objects in kubernetes cluster into helm chart values.

To make migration simpler, chart still offers a way to reference external secrets with new fields in `secrets` map. In order to preserve previous secrets change the following section in `values.yaml`:

```yaml
secretNames:
  credentials: <name-of-secret-with-credentials>
  certificate: <name-of-secret-with-certificate>
  pgbackrest: <name-of-secret-with-pgbackrest-config>
```

to new structure:

```yaml
secrets:
  credentialsSecretName: <name-of-secret-with-credentials>
  certificateSecretName: <name-of-secret-with-certificate>
  pgbackrestSecretName: <name-of-secret-with-pgbackrest-config>
```

# Upgrading from 0.9 to 0.10
The `loadBalancer` & `replicaLoadBalancer` values have been deprecated and will be removed in future releases. These configuration values have been replaced with a more comprehensive configuration pattern for generating Kubernetes Services. The new configuration options are nested under the `service` key, and have two top-level fields: `primary` and `replica`, corresponding to the Kubernetes Service for the primary and replicas respectively.

In order to generate configuration equivalent to the deprecated `loadBalancer` config using the new `service` config, use the following snippet:

```yaml
loadBalancer:
  # If this field remains enabled, then the new `service` config will be ignored.
  enabled: false
service:
  primary:
    type: LoadBalancer
    annotations:
      # This is added by default using the old config, but not the new config.
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "4000"
```

# Upgrading from 0.8 to 0.9
The default Docker Image now points to PostgreSQL 13 instead of PostgreSQL 13,
the default image however does contain the PostgreSQL 12 binaries as well.

If you want to run PostgreSQL 12 on the 0.9 Helm Charts you should set version to 12 in
your `values.yaml`:

```yaml
version: 12
```

If you upgrade from Helm Charts version 0.7 or earlier, you should also follow the upgrade
guide [0.7 to 0.8](#upgrading-from-07x-to-08x)

# Upgrading from 0.7 to 0.8
Version 0.8 includes [Helm Schema Validation](https://helm.sh/docs/topics/charts/#schema-files)
for the `values.yaml` provided to Helm. If you have extra or incorrectly specified values in your
current `values.yaml` an upgrade to 0.8.x will fail.

If you upgrade from Helm Charts version 0.6, you should also follow the upgrade
guide [0.6 to 0.7](#upgrading-from-06x-to-07x)
# Upgrading from 0.6 to 0.7
The default Docker Image now points to PostgreSQL 12 instead of PostgreSQL 11,
the default image however does contain the PostgreSQL 11 binaries as well.

If you want to run PostgreSQL 11 on the 0.7 Helm Charts you should set version to 11 in
your `values.yaml`:

```yaml
version: 11
```

Doing a [`pg_upgrade`](https://www.postgresql.org/docs/12/pgupgrade.html) is (for now) out of scope
for these Helm Charts.

If you upgrade from Helm Charts version 0.5, you should also follow the upgrade
guide [0.5 to 0.6](#upgrading-from-05x-to-06x)

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
