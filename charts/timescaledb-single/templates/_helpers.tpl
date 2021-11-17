{{/*
This file and its contents are licensed under the Apache License 2.0.
Please see the included NOTICE for copyright information and LICENSE for a copy of the license.
*/}}
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "timescaledb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clusterName" -}}
{{- default .Release.Name .Values.clusterName | trunc 63 -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "timescaledb.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "timescaledb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use.
*/}}
{{- define "timescaledb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "timescaledb.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "socket_directory" -}}
/var/run/postgresql
{{- end -}}

{{- define "pod_environment_file" -}}
${HOME}/.pod_environment
{{- end -}}

{{- define "pgbackrest_environment_file" -}}
${HOME}/.pgbackrest_environment
{{- end -}}

{{- define "pgbackrest_bootstrap_environment_dir" -}}
/etc/pgbackrest/bootstrap
{{- end -}}

{{- define "postgres.uid" -}}
{{- default .Values.uid "1000" -}}
{{- end -}}

{{- define "data_directory" -}}
{{ printf "%s/data" .Values.persistentVolumes.data.mountPath }}
{{- end -}}

{{- define "callbacks_dir" -}}
/etc/timescaledb/callbacks
{{- end -}}

{{- define "tablespaces_dir" -}}
{{ printf "%s/tablespaces" .Values.persistentVolumes.data.mountPath }}
{{- end -}}

{{- define "scripts_dir" -}}
/etc/timescaledb/scripts
{{- end -}}

{{- define "post_init_dir" -}}
/etc/timescaledb/post_init.d
{{- end -}}

{{- define "wal_directory" -}}
{{ printf "%s/pg_wal" .Values.persistentVolumes.wal.mountPath }}
{{- end -}}

{{- define "tstune_config" -}}
{{ printf "%s/timescaledb.conf" (include "socket_directory" .) }}
{{- end -}}

{{- define "wal_status_file" -}}
{{ printf "%s/wal_status" (include "socket_directory" .) }}
{{- end -}}

{{- define "secrets_credentials" -}}
{{ printf "%s-credentials" (include "clusterName" .) }}
{{- end -}}

{{- define "secrets_certificate" -}}
{{ printf "%s-certificate" (include "clusterName" .) }}
{{- end -}}

{{- define "secrets_pgbackrest" -}}
{{ printf "%s-pgbackrest" (include "clusterName" .) }}
{{- end -}}
