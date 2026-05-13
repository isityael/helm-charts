# CyberChef Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [CyberChef](https://github.com/gchq/CyberChef).

## Requirements

- Kubernetes >= 1.28
- An Ingress controller or Gateway API implementation (optional)

## Notes

- Default image is `mpepping/cyberchef` and listens on port 8000 (service port 80).
- CyberChef is stateless; no persistence is required by default.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| image.repository | string | `mpepping/cyberchef` | Container image repository |
| image.tag | string | `v10.24.0` | Container image tag |
| service.port | int | `80` | Service port |
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
    - host: cyberchef.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wildcard-example
      hosts:
        - cyberchef.example.com
```

## Gateway API example

```yaml
ingress:
  enabled: false
  hosts:
    - host: cyberchef.example.com
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
    - cyberchef.example.com
```
