{{- define "csi-s3.maintainedImage" -}}
{{- $image := printf "%s:%s" .Values.maintainedImage.repository .Values.maintainedImage.tag -}}
{{- with .Values.maintainedImage.digest -}}
{{- $image = printf "%s@%s" $image . -}}
{{- end -}}
{{- $image -}}
{{- end -}}
