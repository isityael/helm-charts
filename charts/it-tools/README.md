# IT-Tools Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [IT-Tools](https://github.com/CorentinTh/it-tools) using the `bjw-s/common` library.

## Requirements

- Kubernetes >= 1.28
- An Ingress controller (optional)

## Notes

- Default image is `ghcr.io/corentinth/it-tools` and listens on port 80.
- IT-Tools is stateless; no persistence is required.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| controllers.main.containers.main.image.repository | string | `ghcr.io/corentinth/it-tools` | Container image repository |
| controllers.main.containers.main.image.tag | string | `2024.10.22-7ca5933` | Container image tag |
| service.main.ports.http.port | int | `80` | Service port |
| ingress.main.enabled | bool | `false` | Enable ingress |
| serviceAccount.it-tools.enabled | bool | `false` | Create service account |

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
      - host: it-tools.example.com
        paths:
          - path: /
            pathType: Prefix
            service:
              identifier: main
              port: http
    tls:
      - secretName: wildcard-example
        hosts:
          - it-tools.example.com
```
