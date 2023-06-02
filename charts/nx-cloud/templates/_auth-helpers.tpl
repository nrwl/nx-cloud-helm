{{- define "nxCloud.api.auth" }}
# TODO update docs
# TODO test by adding different env vars and see if they get added on the deployment
{{- if .Values.github.auth.enabled }}
- name: GITHUB_AUTH_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAuthClientId }}
- name: GITHUB_AUTH_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.githubAuthClientSecret }}
    {{ if .Values.github.pr.apiUrl }}
- name: GITHUB_API_URL
  value: {{ .Values.github.pr.apiUrl }}
    {{- end }}
{{- end }}

{{- if .Values.gitlab.auth.enabled }}
- name: GITLAB_APP_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.gitlabAppId }}
- name: GITLAB_APP_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.gitlabAppSecret }}
    {{ if .Values.gitlab.apiUrl }}
- name: GITLAB_API_URL
  value: {{ .Values.gitlab.apiUrl }}
    {{- end }}
{{- end }}

{{- if .Values.bitbucket.auth.enabled }}
- name: BITBUCKET_APP_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.bitbucketAppId }}
- name: BITBUCKET_APP_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.bitbucketAppSecret }}
{{- end }}

{{- if .Values.saml.enabled }}
- name: SAML_ENTRY_POINT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.samlEntryPoint }}
- name: SAML_CERT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.name }}
      key: {{ .Values.secret.samlCert }}
{{- end }}
{{- end }}