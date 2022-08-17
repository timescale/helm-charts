#!/bin/bash

set -euo pipefail

alerts="tmp/promscale-alerts.yaml"
file="charts/promscale/templates/prometheus-rule.yaml"

cd "$(git rev-parse --show-toplevel)"

# Remove local tmp directory if exists
if [ -d "tmp/" ]; then
	rm -fr "tmp/"
fi
mkdir -p tmp

wget https://raw.githubusercontent.com/timescale/promscale/master/docs/mixin/alerts/alerts.yaml -O "${alerts}"

cat << EOF > "$file"
{{- /* This file is generated using a script located at scripts/generate-promscale-alerts.sh */}}
{{ if .Values.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: {{ include "promscale.fullname" . }}-rules
  namespace: {{ template "promscale.namespace" . }}
  labels:
{{ include "promscale-helm.labels" . | indent 4 }}
spec:
{{\`
$(sed -e 's/^/  /' < "$alerts")
\`}}
{{- end }}
EOF
