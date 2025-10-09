{{/*
Expand the name of the chart.
*/}}
{{- define "nxCloud.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nxCloud.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nxCloud.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nxCloud.labels" -}}
helm.sh/chart: {{ include "nxCloud.chart" . }}
app.kubernetes.io/name: {{ include "nxCloud.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Merge labels with common labels always included
Usage: {{ include "nxCloud.mergedLabels" (dict "resourceLabels" .Values.ingress.labels "context" .) }}
*/}}
{{- define "nxCloud.mergedLabels" -}}
{{- $resourceLabels := .resourceLabels | default dict -}}
{{- $context := .context -}}
{{- $commonLabels := include "nxCloud.labels" $context | fromYaml -}}
{{- $globalLabels := $context.Values.global.labels | default dict -}}
{{- $mergedLabels := merge $resourceLabels $globalLabels $commonLabels -}}
{{- toYaml $mergedLabels -}}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "nxCloud.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nxCloud.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "nxCloud.env.verboseLogging" }}
{{- if .Values.global.verboseLogging }}
- name: NX_VERBOSE_LOGGING
  value: 'true'
- name: NX_API_LOG_LEVEL
  value: 'DEBUG'
{{- end }}
{{- end }}

{{/*
Strip http:// or https:// prefixes from a URL
*/}}
{{- define "nxCloud.stripURLProtocol" -}}
{{- regexReplaceAll "^https?://" . "" -}}
{{- end -}}

{{/*
Construct the image reference with support for both tag and digest.
If digest is specified, it takes precedence over tag.
If global.imageRegistry is specified, it will be prepended to the repository.
Usage: {{ include "nxCloud.image" (dict "image" .Values.api.image "global" .Values.global) }}
*/}}
{{- define "nxCloud.image" -}}
{{- $registry := .global.imageRegistry | default "" -}}
{{- $repository := .image.repository -}}
{{- $digest := .image.digest | default "" -}}
{{- $tag := .image.tag | default .global.imageTag -}}
{{- $fullRepository := $repository -}}
{{- if $registry -}}
{{- $fullRepository = printf "%s/%s" (trimSuffix "/" $registry) $repository -}}
{{- end -}}
{{- if $digest -}}
{{- printf "%s@%s" $fullRepository $digest -}}
{{- else -}}
{{- printf "%s:%s" $fullRepository $tag -}}
{{- end -}}
{{- end -}}
