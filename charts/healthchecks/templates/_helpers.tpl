{{- define "healthchecks.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "healthchecks.fullname" -}}
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

{{- define "healthchecks.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "healthchecks.labels" -}}
helm.sh/chart: {{ include "healthchecks.chart" . }}
{{ include "healthchecks.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "healthchecks.selectorLabels" -}}
app.kubernetes.io/name: {{ include "healthchecks.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "healthchecks.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "healthchecks.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "healthchecks.env" -}}
{{- range $name, $value := .Values.env }}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end }}
{{- if .Values.database.existingSecret.name }}
- name: DB_HOST
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.host }}
- name: DB_PORT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.port }}
- name: DB_NAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.name }}
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.user }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.keys.password }}
{{- else }}
- name: DB_HOST
  value: {{ .Values.database.values.host | quote }}
- name: DB_PORT
  value: {{ .Values.database.values.port | quote }}
- name: DB_NAME
  value: {{ .Values.database.values.name | quote }}
- name: DB_USER
  value: {{ .Values.database.values.user | quote }}
{{- end }}
{{- range $name, $ref := .Values.secretEnv }}
{{- if $ref.secretName }}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ $ref.secretName }}
      key: {{ $ref.key }}
{{- end }}
{{- end }}
{{- with .Values.extraEnv }}
{{- toYaml . }}
{{- end }}
{{- end }}
