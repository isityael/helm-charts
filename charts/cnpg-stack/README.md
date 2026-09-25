# cnpg-stack

One chart for a complete CloudNativePG setup, shared by the m0sh1 clusters
(`cnpg-root` on root01 and `cnpg-home` on the homelab):

- CNPG operator (`cloudnative-pg-chart` from `oci://dhi.io`)
- Barman Cloud plugin (`plugin-barman-cloud`)
- `Cluster` with optional managed roles
- `Database` resources and a role/database bootstrap Job (Argo CD sync hook)
- Optional backups: `ObjectStore`, `ScheduledBackup` and a one-off `Backup`
- PgBouncer `Pooler`, with an optional PodDisruptionBudget, anti-affinity and
  topology spread
- Scrape objects for the cluster and pooler exporters (`VMPodScrape` or
  `PodMonitor`)

## Requirements

- Kubernetes 1.29+
- Credentials for `dhi.io` (operator chart and images)
- For backups: an S3-compatible endpoint and a Secret with the access keys
- For scraping: the VictoriaMetrics operator (`VMPodScrape`, default) or the
  Prometheus operator (`cnpg.metrics.scrapeKind: PodMonitor`)
- `cnpg.pgbouncer.image` must provide PgBouncer at `/usr/bin/pgbouncer`, which
  the CNPG Pooler manager expects

## Install

```bash
helm install cnpg oci://ghcr.io/isityael/charts/cnpg-stack --version 0.14.1 \
  --namespace cnpg-system --create-namespace -f values.yaml
```

As a dependency of a wrapper chart (the pattern the m0sh1 clusters use),
nest all values under `cnpg-stack:`:

```yaml
dependencies:
  - name: cnpg-stack
    version: 0.14.1
    repository: oci://ghcr.io/isityael/charts
```

## Configuration

All settings live under `cnpg`; the operator and plugin keep their upstream
values under `cloudnative-pg` and `plugin-barman-cloud`.

| Key | Purpose |
| --- | --- |
| `cnpg.cluster.*` | Cluster name, namespace, instances, operand image, storage, WAL storage, resources, PostgreSQL parameters, affinity, tolerations, topology spread |
| `cnpg.cluster.backup.*` | Barman Cloud `ObjectStore`, schedule, retention, sidecar tuning; `manual.enabled` renders a one-off `Backup` |
| `cnpg.roles[]` | Managed roles; `ensure: absent` keeps a retired role reconciled as deleted |
| `cnpg.databases[]` | `Database` resources; rendered when `enabled` or `ensure` is set |
| `cnpg.pgbouncer.*` | Pooler size, pool parameters, resources, `pdb`, `affinity`, `topologySpreadConstraints`, `rolloutNonce` |
| `cnpg.metrics.*` | Scrape kind, namespace (defaults to the release namespace), `release` label, cluster scrape name and instance-only selector |

Resource names come from `cnpg.cluster.name` (for example `<name>-pooler` and
`<name>-rw`), never from the release or chart name. That keeps them stable
when the chart is consumed as a dependency.

`Database` resources are named `<cluster>-<database>`, with the database name
lowercased and `_` mapped to `-`. Names longer than 63 characters are
shortened and get a hash suffix so two databases can't collide.

## Values examples

Single-instance cluster with backups to Garage:

```yaml
cnpg:
  cluster:
    name: cnpg-main
    namespace: apps
    instances: 1
    storage: {class: zfs-cnpg-csi, size: 20Gi}
    walStorage: {class: zfs-cnpg-wal-csi, size: 5Gi}
    backup:
      enabled: true
      objectStoreName: cnpg-backups
      destinationPath: s3://root-cnpg-backups/
      endpointURL: http://garage-root.apps.svc.cluster.local:3900
      s3Credentials:
        accessKeyId: {name: cnpg-garage-s3-creds, key: ACCESS_KEY_ID}
        secretAccessKey: {name: cnpg-garage-s3-creds, key: ACCESS_SECRET_KEY}
  roles:
    - name: app
      enabled: true
      passwordSecret: {name: app-postgres-auth}
  databases:
    - name: app
      enabled: true
      owner: app
      databaseReclaimPolicy: retain
```

Highly available pooler scraped by kube-prometheus-stack:

```yaml
cnpg:
  pgbouncer:
    replicas: 2
    affinity:
      enablePodAntiAffinity: true
      podAntiAffinityType: required
  metrics:
    releaseLabel: kube-prometheus-stack
```

## Upgrade notes

### 0.14.1

The sync hook only creates missing roles. CNPG `managed.roles` owns subsequent
role and password reconciliation. Reapplying the same password from the hook
regenerated its SCRAM verifier on every sync, invalidating credentials cached by
existing PgBouncer sessions. Database bootstrap and pooler authentication grants
remain idempotent and run as before.

### 0.14.0

The chart was rebuilt from the templates the live clusters run
(`infra/root/apps/cnpg-root` and `infra/apps/cluster/cnpg-home`), and it
renders both of them with no object differences. Compared with 0.13.x:

- New keys: `cnpg.metrics.*`, `cnpg.pgbouncer.pdb`, `cnpg.pgbouncer.affinity`,
  `cnpg.pgbouncer.topologySpreadConstraints`, `cnpg.pgbouncer.rolloutNonce`,
  `cnpg.cluster.backup.manual`.
- Removed: `cnpg.pgbouncer.metrics.namespace` and
  `cnpg.pgbouncer.metrics.vmPodScrape`. Use `cnpg.metrics.namespace` and
  `cnpg.metrics.scrapeKind` instead.
- `Database` names no longer get a hash suffix for names containing `_`.
- `cloudnative-pg.updateStrategy` and `cnpg.cluster.monitoring` are no longer
  set by default. Set them explicitly if you relied on them.
- PgBouncer defaults: `minPoolSize` 0 (was 5) and `serverIdleTimeout` 300
  (was 600).
- The operator's Grafana dashboard stays off
  (`cloudnative-pg.monitoring.grafanaDashboard.create: false`). Helm can't
  see the operator chart's own default once this chart is itself a
  dependency.
