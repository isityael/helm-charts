{{/*
Expand the chart name.
*/}}
{{- define "m0sh1-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the chart fullname.
*/}}
{{- define "m0sh1-exporter.fullname" -}}
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
OPNsense exporter component name. Defaults to opnsense-exporter to preserve
the Prometheus job identity while the umbrella app moves to m0sh1-exporter.
*/}}
{{- define "m0sh1-exporter.opnsenseName" -}}
{{- default (include "m0sh1-exporter.fullname" .) .Values.opnsenseExporter.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "m0sh1-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "m0sh1-exporter.labels" -}}
helm.sh/chart: {{ include "m0sh1-exporter.chart" . }}
{{ include "m0sh1-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for the OPNsense exporter component.
*/}}
{{- define "m0sh1-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "m0sh1-exporter.opnsenseName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
