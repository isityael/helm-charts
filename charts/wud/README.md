# WUD Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [WUD (What's Up Docker)](https://github.com/getwud/wud) using the `bjw-s/common` library.

## Requirements

- Kubernetes >= 1.28
- An Ingress controller (optional)

## Notes

- Default image is `getwud/wud` and listens on port 3000.
- Provide watcher credentials via a Secret and reference it with `envFromSecret`.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| controllers.main.containers.main.image.repository | string | `getwud/wud` | Container image repository |
| controllers.main.containers.main.image.tag | string | `8.1.1` | Container image tag |
| envFromSecret | string | `""` | Secret name to mount as envFrom |
| service.main.ports.http.port | int | `3000` | Service port |
| ingress.main.enabled | bool | `false` | Enable ingress |
| serviceAccount.wud.enabled | bool | `false` | Create service account |

For full configuration options, see `values.yaml`.

## Ingress example

```yaml
ingress:
  main:
    enabled: true
    className: traefik
    annotations:
      traefik.ingress.kubernetes.io/router.entrypoints: websecure
      traefik.ingress.kubernetes.io/router.tls: "true"
    hosts:
      - host: wud.example.com
        paths:
          - path: /
            pathType: Prefix
            service:
              identifier: main
              port: http
    tls:
      - secretName: wildcard-example
        hosts:
          - wud.example.com
```
