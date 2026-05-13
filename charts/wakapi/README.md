# Wakapi Helm Chart

Helm chart for [Wakapi](https://wakapi.dev), a self-hosted WakaTime-compatible coding statistics service.

## Requirements

- Kubernetes >= 1.28
- Persistent storage when using SQLite
- PostgreSQL when `config.db.dialect: postgres`
- Prometheus Operator CRDs when `serviceMonitor.enabled` is `true`
- An Ingress controller or Gateway API implementation when external access is enabled

## Install

```bash
helm repo add sm-moshi https://sm-moshi.github.io/helm-charts
helm repo update

helm install wakapi sm-moshi/wakapi -n wakapi --create-namespace -f values.yaml
```

## Configuration

Non-sensitive Wakapi configuration is rendered into a ConfigMap. Sensitive values such as database passwords, OIDC client secrets, and SMTP passwords should be referenced through `existingSecrets`.

## Values Example

```yaml
config:
  server:
    public_url: https://wakapi.example.com
  db:
    dialect: postgres
    host: postgres-rw.database.svc.cluster.local
    port: "5432"
    user: wakapi
    name: wakapi

existingSecrets:
  dbPassword:
    secretName: wakapi-postgres-auth
    key: password

serviceMonitor:
  enabled: true
```

## Ingress Example

```yaml
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: wakapi.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wildcard-example
      hosts:
        - wakapi.example.com
```
