{{/*
Override the upstream gitea.image helper so custom rootless-compatible images
do not receive the upstream chart's automatic "-rootless" tag suffix.

The override still runs in the upstream subchart context, so .Values below are
the upstream Forgejo chart values.
*/}}
{{- define "gitea.image" -}}
{{- if .Values.image.fullOverride -}}
{{- .Values.image.fullOverride -}}
{{- else -}}
{{- if .Values.image.registry -}}{{ .Values.image.registry }}/{{- end -}}
{{- .Values.image.repository -}}:{{- .Values.image.tag | default .Chart.AppVersion -}}
{{- end -}}
{{- end -}}
