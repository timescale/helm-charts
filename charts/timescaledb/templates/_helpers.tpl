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
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "timescaledb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "timescaledb.labels" -}}
helm.sh/chart: {{ include "timescaledb.chart" . }}
{{ include "timescaledb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "timescaledb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "timescaledb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "timescaledb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "timescaledb.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
The prefix of the certificate secrets
*/}}
{{- define "certificatePrefix" -}}
{{ template "timescaledb.fullname" $ }}-certificate
{{- end -}}

{{/*
The prefix of the patroni users
*/}}
{{- define "patroniUsersPrefix" -}}
{{ template "timescaledb.fullname" $ }}-users-patroni
{{- end -}}

{{/*
The access node name

We include some sanity checking here, to ensure the Chart will fail during templating if
the accessNode is specified incorrectly. When there is only 1 node specified, we assume that
node to be the accessNode. If multiple nodes are specified, the accessNode needs to be explicitly
set.
*/}}
{{- define "accessNode" -}}
{{- if .Values.spec.accessNode -}}
{{- $_ := required (printf "The specified accessNode (%s) should be one of the configured nodes" .Values.spec.accessNode) (index .Values.spec.nodes .Values.spec.accessNode) -}}
{{ .Values.spec.accessNode }}
{{- else if (eq (len .Values.spec.nodes) 1) -}}
{{ keys .Values.spec.nodes | first }}
{{- else -}}
{{- fail "specifying the accessNode is required when configuring multiple nodes" -}}
{{- end -}}
{{- end -}}


{{- define "socket_directory" -}}
/var/run/postgresql
{{- end -}}

{{- define "data_mountpoint" -}}
/var/lib/postgresql/
{{- end -}}

{{- define "wal_mountpoint" -}}
/var/lib/postgresql/wal
{{- end -}}

{{- define "data_directory" -}}
/var/lib/postgresql/data
{{- end -}}

{{- define "callbacks_dir" -}}
/etc/timescaledb/callbacks
{{- end -}}

{{- define "scripts_dir" -}}
/etc/timescaledb/scripts
{{- end -}}

{{- define "wal_directory" -}}
/var/lib/postgresql/pg_wal
{{- end -}}

{{- define "tstune_config" -}}
{{ printf "%s/timescaledb.conf" (include "socket_directory" .) }}
{{- end -}}
