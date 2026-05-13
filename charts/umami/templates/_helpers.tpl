{{- define "umami.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "umami.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "umami.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "umami.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "umami.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "umami.selectorLabels" -}}
app.kubernetes.io/name: {{ include "umami.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "umami.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "umami.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "umami.bootstrapName" -}}
{{- printf "%s-bootstrap" (include "umami.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "umami.bootstrapLabels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: umami-bootstrap
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "umami.databaseUrl" -}}
{{- $db := .Values.database.generated -}}
{{- printf "%s://%s:$(DATABASE_PASSWORD)@%s:%v/%s?sslmode=%s" $db.protocol $db.user $db.host $db.port $db.name $db.sslmode -}}
{{- end -}}
