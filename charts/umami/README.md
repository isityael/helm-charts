# Umami Helm Chart

Deploys [Umami](https://umami.is), a privacy-focused web analytics platform.

## Requirements

- Kubernetes 1.28+
- PostgreSQL 12.14+
- A Kubernetes Secret containing `APP_SECRET`
- A PostgreSQL connection string or enough values to generate one from an existing password Secret

## Install

```bash
helm install umami oci://ghcr.io/sm-moshi/charts/umami \
  --version 0.2.0 \
  --namespace apps \
  --create-namespace \
  --values values.yaml
```

## Minimal Values

```yaml
database:
  generated:
    enabled: true
    host: cnpg-main-pooler.apps.svc.cluster.local
    name: umami
    user: umami
    passwordSecret:
      name: umami-postgres-auth
      key: password

appSecret:
  existingSecret:
    name: umami-config
    key: app-secret
```

## Gateway API

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: traefik-gateway
      namespace: traefik
      sectionName: websecure
  hostnames:
    - analytics.example.com
```

## Runtime Settings

Common Umami environment variables are exposed under `config`.

```yaml
config:
  clientIpHeader: CF-Connecting-IP
  disableUpdates: "1"
  forceSsl: "1"
  trackerScriptName: analytics
```

Use `extraEnv` and `extraEnvSecrets` for settings that are not modeled directly by the chart.

## Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

## Custom Tracker Script

```yaml
customScript:
  enabled: true
  key: script.js
  mountPath: /app/public/script.js
  data: |
    window.umamiCustomScriptLoaded = true;
```

## Bootstrap

The optional bootstrap Job can rotate the default `admin` password and create a website with a stable ID.
It defaults to the Docker Hardened Images Python image. Configure `bootstrap.imagePullSecrets` if your cluster
requires an authenticated DHI pull secret.

```yaml
bootstrap:
  enabled: true
  imagePullSecrets:
    - name: kubernetes-dhi
  admin:
    passwordSecret:
      name: umami-config
      key: admin-password
  website:
    id: d6e7b90a-b812-4edb-85a4-f1439940db48
    name: example.com
    domain: example.com
```

The Job talks to Umami through the in-cluster Service and is idempotent.
