{{- define "nxCloud.frontend.scm.all" }}
    {{- if .Values.vcsHttpsProxy }}
- name: VERSION_CONTROL_HTTPS_PROXY
  value: {{ .Values.vcsHttpsProxy }}
    {{- end }}
{{- end }}

{{- define "nxCloud.frontend.scm.githubAppEnv" }}
{{- if .Values.secret.name }}
    {{- if .Values.secret.githubAppId }}
- name: NX_CLOUD_GITHUB_APP_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAppId }}
- name: NX_CLOUD_GITHUB_APP_APP_ID
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
    {{- if .Values.secret.githubWebhookSecret }}
- name: NX_CLOUD_GITHUB_WEBHOOK_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubWebhookSecret }}
    {{- end }}
    {{- if .Values.secret.githubAppClientId }}
- name: NX_CLOUD_GITHUB_APP_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAppClientId }}
    {{- end }}
    {{- if .Values.secret.githubAppClientSecret }}
- name: NX_CLOUD_GITHUB_APP_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAppClientSecret }}
    {{- end }}
{{- end }}
{{- end }}