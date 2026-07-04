{{- define "youtarr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "youtarr.fullname" -}}
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

{{- define "youtarr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "youtarr.labels" -}}
helm.sh/chart: {{ include "youtarr.chart" . }}
{{ include "youtarr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "youtarr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "youtarr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "youtarr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "youtarr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "youtarr.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- if .Values.image.digest -}}
{{- printf "%s:%s@%s" .Values.image.repository $tag .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end }}

{{- define "youtarr.mariadbImage" -}}
{{- if .Values.mariadb.image.digest -}}
{{- printf "%s:%s@%s" .Values.mariadb.image.repository .Values.mariadb.image.tag .Values.mariadb.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.mariadb.image.repository .Values.mariadb.image.tag -}}
{{- end -}}
{{- end }}

{{- define "youtarr.mariadb.fullname" -}}
{{- printf "%s-mariadb" (include "youtarr.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "youtarr.mariadb.secretName" -}}
{{- default (printf "%s-mariadb" (include "youtarr.fullname" .)) .Values.mariadb.auth.existingSecret.name }}
{{- end }}

{{- define "youtarr.dbHost" -}}
{{- if eq .Values.database.type "embedded" -}}
{{- include "youtarr.mariadb.fullname" . -}}
{{- else -}}
{{- .Values.externalDatabase.host -}}
{{- end -}}
{{- end }}

{{- define "youtarr.dbPort" -}}
{{- if eq .Values.database.type "embedded" -}}
{{- 3306 -}}
{{- else -}}
{{- .Values.externalDatabase.port -}}
{{- end -}}
{{- end }}

{{- define "youtarr.dbName" -}}
{{- if eq .Values.database.type "embedded" -}}
{{- .Values.mariadb.auth.database -}}
{{- else -}}
{{- .Values.externalDatabase.database -}}
{{- end -}}
{{- end }}

{{- define "youtarr.dbUser" -}}
{{- if eq .Values.database.type "embedded" -}}
{{- .Values.mariadb.auth.username -}}
{{- else -}}
{{- .Values.externalDatabase.username -}}
{{- end -}}
{{- end }}

{{- define "youtarr.dbSecretName" -}}
{{- if eq .Values.database.type "embedded" -}}
{{- include "youtarr.mariadb.secretName" . -}}
{{- else -}}
{{- .Values.externalDatabase.existingSecret.name -}}
{{- end -}}
{{- end }}

{{- define "youtarr.dbPasswordKey" -}}
{{- if eq .Values.database.type "embedded" -}}
{{- .Values.mariadb.auth.existingSecret.passwordKey -}}
{{- else -}}
{{- .Values.externalDatabase.existingSecret.passwordKey -}}
{{- end -}}
{{- end }}

{{- define "youtarr.persistence.claimName" -}}
{{- $root := index . 0 -}}
{{- $name := index . 1 -}}
{{- $cfg := index . 2 -}}
{{- default (printf "%s-%s" (include "youtarr.fullname" $root) $name) $cfg.existingClaim -}}
{{- end }}
