# Homepage Helm Chart

Helm chart for [Homepage](https://github.com/gethomepage/homepage) using the `bjw-s/common` library.

## Requirements

- Kubernetes >= 1.28
- An Ingress controller (optional)
- Metrics server (optional, for Kubernetes widgets)

## Notes

- Set `controllers.main.containers.main.env[HOMEPAGE_ALLOWED_HOSTS]` to your hostname.
- Config files are mounted into `/app/config` from a generated ConfigMap.
- Enable RBAC with `rbac.enabled: true` to use Kubernetes integration.

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
