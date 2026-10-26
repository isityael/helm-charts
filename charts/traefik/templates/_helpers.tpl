{{/*
Override upstream traefik.image-name to support empty registry field.
Image Updater writes the full image path (registry/repo) into
image.repository, leaving image.registry empty.
*/}}
{{- define "traefik.image-name" -}}
{{- if .Values.image.registry -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end -}}
{{- end -}}

{{/* Internal HTTP only: TLS and certificates belong to the shared gateway. */}}
{{- define "traefik.securityTxtCaddyfile" -}}
{
    admin off
    auto_https off
    persist_config off
}
:8080 {
    root * /usr/share/caddy
    header -Server
    file_server
    handle_errors {
        header -Server
        respond "" {err.status_code}
    }
}
{{- end -}}
