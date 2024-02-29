{{- define "nxCloud.app.name" }}
{{- .Chart.Name | default .Values.naming.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nxCloud.app.chartName" }}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nxCloud.app.selectorLabels" }}
app.kubernetes.io/name: {{ include "nxCloud.app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{/*
Common labels
*/}}
{{- define "nxCloud.app.labels" }}
helm.sh/chart: {{ include "nxCloud.app.chartName" . }}
{{- include "nxCloud.app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}