{{/*
Expand the name of the chart.
*/}}
{{- define "basic-memory.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "basic-memory.fullname" -}}
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
{{- define "basic-memory.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "basic-memory.labels" -}}
helm.sh/chart: {{ include "basic-memory.chart" . }}
{{ include "basic-memory.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "basic-memory.selectorLabels" -}}
app.kubernetes.io/name: {{ include "basic-memory.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "basic-memory.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "basic-memory.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Effective Service targetPort — when the MCP shim is enabled, the Service
targets the shim sidecar on 8000 (or whatever service.targetPort is set to).
When the shim is disabled, it targets the upstream Basic Memory server
directly on basicMemory.upstreamPort.
*/}}
{{- define "basic-memory.effectiveTargetPort" -}}
{{- if .Values.mcpShim.enabled -}}
{{ .Values.service.targetPort }}
{{- else -}}
{{ .Values.basicMemory.upstreamPort }}
{{- end -}}
{{- end }}

{{/*
Image tag with fallback to chart appVersion.
*/}}
{{- define "basic-memory.imageTag" -}}
{{- default .Chart.AppVersion .Values.image.tag }}
{{- end }}
