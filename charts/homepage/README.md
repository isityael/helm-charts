# Homepage Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [Homepage](https://github.com/gethomepage/homepage) using the `bjw-s/common` library.

## Requirements

- Kubernetes >= 1.28
- An Ingress controller (optional)
- Metrics server (optional, for Kubernetes widgets)

## Notes

- Set `controllers.main.containers.main.env[HOMEPAGE_ALLOWED_HOSTS]` to your hostname.
- Config files are mounted into `/app/config` from a generated ConfigMap.
- Enable RBAC with `rbac.enabled: true` to use Kubernetes integration.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| controllers.main.containers.main.image.repository | string | `ghcr.io/gethomepage/homepage` | Container image repository |
| controllers.main.containers.main.image.tag | string | `v1.8.0` | Container image tag |
| controllers.main.containers.main.env | list | `[]` | Environment variables (set `HOMEPAGE_ALLOWED_HOSTS`) |
| service.main.ports.http.port | int | `3000` | Service port |
| ingress.main.enabled | bool | `false` | Enable ingress |
| rbac.enabled | bool | `false` | Enable RBAC |
| serviceAccount.homepage.enabled | bool | `false` | Create service account |
| config.useExistingConfigMap | string | `""` | Use an existing ConfigMap |
| config.extraFiles | map | `{}` | Extra config files mounted into `/app/config` |
| persistence.logs.enabled | bool | `true` | Enable logs volume |

For full configuration options, see `values.yaml`.

## Examples

Basic install:

```yaml
controllers:
  main:
    containers:
      main:
        env:
          - name: HOMEPAGE_ALLOWED_HOSTS
            value: home.example.com

ingress:
  main:
    enabled: true
    className: traefik
    hosts:
      - host: home.example.com
        paths:
          - path: /
            pathType: Prefix
            service:
              identifier: main
              port: http
    tls:
      - hosts:
          - home.example.com
        secretName: wildcard-example
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
