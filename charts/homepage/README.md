# Homepage Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [Homepage](https://github.com/gethomepage/homepage).

## Requirements

- Kubernetes >= 1.28
- An Ingress controller or Gateway API implementation (optional)
- Metrics server (optional, for Kubernetes widgets)

## Notes

- Set `env` with `HOMEPAGE_ALLOWED_HOSTS` for your hostname.
- Config files are mounted into `/app/config` from a generated ConfigMap.
- Enable RBAC with `rbac.enabled: true` to use Kubernetes integration.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| image.repository | string | `ghcr.io/gethomepage/homepage` | Container image repository |
| image.tag | string | `v1.13.1` | Container image tag |
| env | list | `[]` | Environment variables (set `HOMEPAGE_ALLOWED_HOSTS`) |
| service.port | int | `3000` | Service port |
| ingress.enabled | bool | `false` | Enable ingress |
| rbac.enabled | bool | `false` | Enable RBAC |
| serviceAccount.create | bool | `false` | Create service account |
| config.useExistingConfigMap | string | `""` | Use an existing ConfigMap |
| config.extraFiles | map | `{}` | Extra config files mounted into `/app/config` |
| persistence.logs.enabled | bool | `true` | Enable logs volume |

For full configuration options, see `values.yaml`.

## Examples

Basic install:

```yaml
env:
  - name: HOMEPAGE_ALLOWED_HOSTS
    value: home.example.com

ingress:
  enabled: true
  className: traefik
  hosts:
    - host: home.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - home.example.com
      secretName: wildcard-example
```

Gateway API exposure:

```yaml
env:
  - name: HOMEPAGE_ALLOWED_HOSTS
    value: home.example.com

ingress:
  enabled: false
  hosts:
    - host: home.example.com
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
    - home.example.com
```

Enable Kubernetes widgets:

```yaml
rbac:
  enabled: true

config:
  kubernetes:
    mode: cluster
  widgets:
    - kubernetes:
        cluster:
          show: true
          cpu: true
          memory: true
          showLabel: true
          label: cluster
        nodes:
          show: true
          cpu: true
          memory: true
          showLabel: true
```
