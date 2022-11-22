{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "parca-agent.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else if contains .Release.Name $name -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "parca-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Allow the release namespace to be overridden
*/}}
{{- define "parca-agent.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Generate labels to be used
*/}}
{{- define "parca-agent.labels" -}}
app: {{ include "parca-agent.fullname" . }}
chart: {{ template "parca-agent.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- end }}

{{- define "parca-agent-helm.labels" -}}
{{ include "parca-agent.labels" . }}
app.kubernetes.io/name: "parca-agent"
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/component: "observability"
app.kubernetes.io/instance: {{ include "parca-agent.fullname" . | quote }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "parca-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "parca-agent.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
