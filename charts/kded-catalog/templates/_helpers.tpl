{{- define "kded-catalog.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "kded-catalog.labels" -}}
app.kubernetes.io/name: kded-catalog
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
