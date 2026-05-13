# WUD Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [WUD (What's Up Docker)](https://github.com/getwud/wud).

## Requirements

- Kubernetes >= 1.28
- An Ingress controller or Gateway API implementation (optional)

## Notes

- Default image is `getwud/wud` and listens on port 3000.
- Provide watcher credentials via a Secret and reference it with `envFromSecret`.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| image.repository | string | `getwud/wud` | Container image repository |
| image.tag | string | `8.2.2` | Container image tag |
| envFromSecret | string | `""` | Secret name to mount as envFrom |
| service.port | int | `3000` | Service port |
| ingress.enabled | bool | `false` | Enable ingress |
| serviceAccount.create | bool | `false` | Create service account |

For full configuration options, see `values.yaml`.

## Ingress example

```yaml
ingress:
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
  tls:
    - secretName: wildcard-example
      hosts:
        - wud.example.com
```

## Gateway API example

```yaml
ingress:
  enabled: false
  hosts:
    - host: wud.example.com
      paths:
        - path: /
          pathType: Prefix

httpRoute:
  enabled: true
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: traefik-gateway
      namespace: traefik
      sectionName: websecure
  hostnames:
    - wud.example.com
```
