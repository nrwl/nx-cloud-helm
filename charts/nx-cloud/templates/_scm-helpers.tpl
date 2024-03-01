{{- define "nxCloud.frontend.scm.github" }}
{{- if .Values.github.pr.enabled }}
  {{- if eq .Values.github.pr.mode "webhook" }}
- name: NX_CLOUD_VCS_INTEGRATION_TYPE
  value: 'GITHUB_WEBHOOK'
    {{- if .Values.github.pr.apiUrl }}
- name: GITHUB_API_URL
  value: {{ .Values.github.pr.apiUrl }}
    {{- end }}
    {{- if .Values.github.pr.remoteRepositoryName }}
- name: NX_CLOUD_REMOTE_REPOSITORY_NAME
  value: {{ .Values.github.pr.remoteRepositoryName }}
    {{- end }}
    {{- if .Values.secret.name }}
- name: GITHUB_WEBHOOK_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubWebhookSecret }}
- name: GITHUB_AUTH_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAuthToken }}
{{- end }}
{{- if .Values.github.pr.defaultWorkspaceId }}
- name: NX_CLOUD_INTEGRATION_DEFAULT_WORKSPACE_ID
  value: {{ .Values.github.pr.defaultWorkspaceId }}
    {{- end }}
  {{- end }}
  {{- if eq .Values.github.pr.mode "eventless" }}
- name: NX_CLOUD_VCS_INTEGRATION_TYPE
  value: 'GITHUB_EVENTLESS'
    {{- if .Values.github.pr.apiUrl }}
- name: NX_CLOUD_GITHUB_API_URL
  value: {{ .Values.github.pr.apiUrl }}
    {{- end }}
    {{- if .Values.github.pr.remoteRepositoryName }}
- name: NX_CLOUD_REMOTE_REPOSITORY_NAME
  value: {{ .Values.github.pr.remoteRepositoryName }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "nxCloud.frontend.scm.gitlab" }}
{{- if .Values.gitlab.mr.enabled }}
- name: NX_CLOUD_VCS_INTEGRATION_TYPE
  value: "GITLAB_EVENTLESS"
  {{- if .Values.gitlab.projectId }}
- name: NX_CLOUD_GITLAB_PROJECT_ID
  value: {{ .Values.gitlab.projectId }}
  {{- end }}
  {{- if .Values.gitlab.apiUrl }}
- name: NX_CLOUD_GITLAB_BASE_URL
  value: {{ .Values.gitlab.apiUrl }}
  {{- end }}
  {{- if .Values.secret.name }}
    {{- if .Values.secret.gitlabAccessToken }}
- name: NX_CLOUD_GITLAB_ACCESS_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.gitlabAccessToken }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "nxCloud.frontend.scm.all" }}
{{- include "nxCloud.frontend.scm.github" . }}
{{- include "nxCloud.frontend.scm.gitlab" . }}
    {{- if .Values.vcsHttpsProxy }}
- name: VERSION_CONTROL_HTTPS_PROXY
  value: {{ .Values.vcsHttpsProxy }}
    {{- end }}
{{- end }}

{{- define "nxCloud.frontend.scm.githubAppEnv" }}
{{- if .Values.secret.name }}
    {{- if .Values.secret.githubAuthToken }}
- name: NX_CLOUD_GITHUB_AUTH_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAuthToken }}
    {{- end }}
    {{- if .Values.secret.githubAppId }}
- name: NX_CLOUD_GITHUB_APP_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAppId }}
    {{- end }}
    {{- if .Values.secret.githubPrivateKey }}
- name: NX_CLOUD_GITHUB_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubPrivateKey }}
    {{- end }}
{{- end }}
{{- end }}