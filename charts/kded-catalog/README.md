# kded-catalog

Private update catalog with PostgreSQL persistence and bounded source workers.

## Requirements

Kubernetes >=1.28, an existing PostgreSQL database and dedicated basic-auth Secret,
and the PostgreSQL CA certificate Secret. Tailscale Kubernetes operator and Cilium
are required when their integrations are enabled. No application PVC is used.

## Install

Publish and verify an immutable application image, then provide its real digest
in `image.spec` and set `enabled=true`. The chart defaults to disabled and refuses
unpinned enabled images. Install using the infrastructure GitOps workflow.

## Configuration

`postgres.existingSecret` must contain `username` and `password`. Only `ca.crt`
from `postgres.caSecret` is mounted; connections require hostname verification.
Workers default to concurrency four, one request per source and a two-second
source interval. All catalog state lives in PostgreSQL. Database creation and
credentials are managed separately from this application chart.

## Values example

```yaml
enabled: false
postgres:
  host: cnpg-main-rw.apps.svc.cluster.local
  database: kded_catalog
  existingSecret: kded-catalog-postgres-auth
  caSecret: cnpg-main-ca
networkPolicy:
  sourceHosts: [downloads.example.org]
```

Allow each exact HTTPS source and redirect hostname explicitly. The application
must also validate destinations and pin resolved public IPs: network policy alone
does not provide application SSRF protection.

## Ingress example

```yaml
tailscale:
  enabled: true
  hostname: kded-catalog
  proxyClass: ts-standalone-ingress
```

This creates a tailnet HTTPS Ingress. No public Ingress or DNS record is created.
