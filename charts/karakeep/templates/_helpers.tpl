{{- define "karakeep.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "karakeep.fullname" -}}
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

{{- define "karakeep.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "karakeep.labels" -}}
helm.sh/chart: {{ include "karakeep.chart" . }}
{{ include "karakeep.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "karakeep.selectorLabels" -}}
app.kubernetes.io/name: {{ include "karakeep.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "karakeep.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "karakeep.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "karakeep.meilisearchUrl" -}}
{{- if .Values.meilisearch.url -}}
{{ .Values.meilisearch.url }}
{{- else if .Values.meilisearch.enabled -}}
http://{{ include "karakeep.fullname" . }}-meilisearch:7700
{{- end -}}
{{- end }}

{{- define "karakeep.browserUrl" -}}
{{- if .Values.browser.url -}}
{{ .Values.browser.url }}
{{- else if .Values.browser.enabled -}}
http://{{ include "karakeep.fullname" . }}-browser:9222
{{- end -}}
{{- end }}

{{- define "karakeep.env" -}}
{{- range $name, $value := .Values.env }}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end }}
- name: DB_DRIVER
  value: postgres
{{- if .Values.database.url }}
- name: DATABASE_URL
  value: {{ .Values.database.url | quote }}
{{- else if and .Values.database.existingSecret.name .Values.database.existingSecret.keys.url }}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.url }}
{{- else if .Values.database.existingSecret.name }}
- name: POSTGRES_HOST
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.host }}
- name: POSTGRES_PORT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.port }}
- name: POSTGRES_DATABASE
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.name }}
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.user }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.password }}
{{- else }}
- name: POSTGRES_HOST
  value: {{ .Values.database.values.host | quote }}
- name: POSTGRES_PORT
  value: {{ .Values.database.values.port | quote }}
- name: POSTGRES_DATABASE
  value: {{ .Values.database.values.name | quote }}
- name: POSTGRES_USER
  value: {{ .Values.database.values.user | quote }}
- name: POSTGRES_PASSWORD
  value: {{ .Values.database.values.password | quote }}
{{- end }}
{{- if include "karakeep.meilisearchUrl" . }}
- name: MEILI_ADDR
  value: {{ include "karakeep.meilisearchUrl" . | quote }}
{{- end }}
{{- if include "karakeep.browserUrl" . }}
- name: BROWSER_WEB_URL
  value: {{ include "karakeep.browserUrl" . | quote }}
{{- end }}
{{- range $name, $ref := .Values.secretEnv }}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ default (printf "%s-config" (include "karakeep.fullname" $)) $ref.secretName }}
      key: {{ $ref.key }}
{{- end }}
{{- with .Values.extraEnv }}
{{- toYaml . }}
{{- end }}
{{- end }}
