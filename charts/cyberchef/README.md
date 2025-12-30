# CyberChef Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [CyberChef](https://github.com/gchq/CyberChef) using the `bjw-s/common` library.

## Requirements

- Kubernetes >= 1.28
- An Ingress controller (optional)

## Notes

- Default image is `mpepping/cyberchef` and listens on port 8000 (service port 80).
- CyberChef is stateless; no persistence is required by default.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| controllers.main.containers.main.image.repository | string | `mpepping/cyberchef` | Container image repository |
| controllers.main.containers.main.image.tag | string | `v10.19.4` | Container image tag |
| service.main.ports.http.port | int | `80` | Service port |
| ingress.main.enabled | bool | `false` | Enable ingress |
| serviceAccount.cyberchef.enabled | bool | `false` | Create service account |

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
      - host: cyberchef.example.com
        paths:
          - path: /
            pathType: Prefix
            service:
              identifier: main
              port: http
    tls:
      - secretName: wildcard-example
        hosts:
          - cyberchef.example.com
```
