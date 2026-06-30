# Wakapi DHI Helm Chart

Public OCI Helm chart for the [isityael/wakapi-dhi](https://github.com/isityael/wakapi-dhi) hardened Wakapi distribution.

The default image is a maintained fork of [muety/wakapi](https://github.com/muety/wakapi) built as a small non-root
DHI static runtime image with pinned base images and dependency refreshes. The chart keeps the application
configuration generic enough to run the upstream image when desired.

## Requirements

- Kubernetes >= 1.28
- Helm >= 3.8 with OCI registry support
- Persistent storage when using SQLite
- PostgreSQL or MySQL when using an external database
- Prometheus Operator CRDs when `serviceMonitor.enabled` is `true`
- An Ingress controller or Gateway API implementation when external access is enabled

## Install

```bash
helm install wakapi oci://ghcr.io/isityael/charts/wakapi-dhi \
  --version 1.2.18 \
  --namespace wakapi \
  --create-namespace
```

Pull the chart without installing:

```bash
helm pull oci://ghcr.io/isityael/charts/wakapi-dhi --version 1.2.18
```

The OCI package name is `wakapi-dhi`, but the chart defaults `nameOverride` and `fullnameOverride` to `wakapi`
so existing Kubernetes object names remain stable during the fork rename.

## Image Defaults

By default, the chart runs `ghcr.io/isityael/wakapi-dhi:2.17.4-yaelmoshi.2` pinned by digest:

```yaml
image:
  repository: ghcr.io/isityael/wakapi-dhi
  tag: 2.17.4-yaelmoshi.2@sha256:4c431455303060f0d2b0d6f4041da4cbb4fdb72ecbce893c46459a14946e258a
```

To run upstream Wakapi with this chart:

```yaml
image:
  repository: ghcr.io/muety/wakapi
  tag: 2.17.3
```

## Configuration

Non-sensitive Wakapi settings are rendered into a ConfigMap. Sensitive values such as database passwords, password
salts, OIDC client secrets, and SMTP credentials should be referenced through existing Kubernetes Secrets.

The chart does not create plaintext Secret manifests from values.

## PostgreSQL Example

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
    max_conn: 10
    ssl: false
  security:
    allow_signup: false
    expose_metrics: true

existingSecrets:
  dbPassword:
    secretName: wakapi-postgres-auth
    key: password
  passwordSalt:
    secretName: wakapi-password-salt
    key: salt

persistence:
  enabled: false
```

## SQLite Example

Use SQLite for a small single-replica deployment. Keep `strategyType: Recreate` with ReadWriteOnce storage.

```yaml
strategyType: Recreate

config:
  db:
    dialect: sqlite3
    name: /data/wakapi.db

persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 2Gi
```

## OIDC And SMTP Secrets

```yaml
config:
  security:
    disable_local_auth: false
    oidc_allow_signup: true
    oidc:
      name: authentik
      display_name: Authentik
      endpoint: https://auth.example.com/application/o/wakapi/
  mail:
    enabled: true
    sender: wakapi@example.com
    provider: smtp
    smtp:
      host: smtp.example.com
      port: 587
      tls: true

existingSecrets:
  oidc:
    secretName: wakapi-oidc
    clientIdKey: client_id
    clientSecretKey: client_secret
  smtp:
    secretName: wakapi-smtp
    usernameKey: username
    passwordKey: password
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
    - secretName: wakapi-example-tls
      hosts:
        - wakapi.example.com
```

## HTTPRoute Example

`httpRoute` and `ingress` are mutually exclusive. HTTPRoute uses `ingress.hosts[*].paths` for path matches so users can
switch between Ingress and Gateway API without changing path structure.

```yaml
ingress:
  enabled: false
  hosts:
    - host: wakapi.example.com
      paths:
        - path: /
          pathType: Prefix

httpRoute:
  enabled: true
  parentRefs:
    - name: public-gateway
      namespace: gateway
      sectionName: https
  hostnames:
    - wakapi.example.com
```

## Metrics Scraping

Wakapi metrics must be exposed by application config and collected through either
VictoriaMetrics Operator `VMServiceScrape` or Prometheus Operator `ServiceMonitor`.
The `/api/metrics` endpoint is authenticated by Wakapi. Store the base64-encoded
Wakapi API key in a Kubernetes Secret and reference it through
`authorization.credentials`; do not store the plain API key in values.

### VictoriaMetrics VMServiceScrape Example

Use this path when vmagent is the native scraper.

```yaml
config:
  security:
    expose_metrics: true

vmServiceScrape:
  enabled: true
  interval: 60s
  path: /api/metrics
  labels:
    release: prometheus-agent
  authorization:
    type: Bearer
    credentials:
      name: wakapi-metrics-token
      key: token
```

### Prometheus ServiceMonitor Example

Use this path only when Prometheus Operator `ServiceMonitor` resources are the
desired integration surface.

```yaml
config:
  security:
    expose_metrics: true

serviceMonitor:
  enabled: true
  interval: 60s
  path: /api/metrics
  additionalLabels:
    release: kube-prometheus-stack
  authorization:
    type: Bearer
    credentials:
      name: wakapi-metrics-token
      key: token
```

## Operational Defaults

- The pod runs as non-root with `allowPrivilegeEscalation: false`, dropped Linux capabilities, and RuntimeDefault seccomp.
- The root filesystem is read-only; writable paths are mounted at `/data` and `/tmp`.
- Service account token automount is disabled by default.
- Liveness and readiness probes default to `/api/health` and can be tuned through `probes`.
- `revisionHistoryLimit`, `podLabels`, `priorityClassName`, and `topologySpreadConstraints` are available for production scheduling policies.

## Upgrade Notes

### 1.2.1

- Default image changed from `ghcr.io/muety/wakapi` to `ghcr.io/isityael/wakapi-dhi`.
- `appVersion` changed to `2.17.3-yaelmoshi.2`.
- Existing values remain compatible. Set `image.repository: ghcr.io/muety/wakapi` and an upstream tag to keep using the upstream image.
- The chart schema now validates common values more strictly while still allowing additional Wakapi config keys under `config`.
