# cnpg-stack

CloudNativePG wrapper chart for deploying:

- CNPG operator (`cloudnative-pg-chart` from `oci://dhi.io`)
- CNPG barman plugin (`plugin-barman-cloud`)
- `Cluster` CR
- optional `ObjectStore` + `ScheduledBackup` CRs
- `Pooler` (PgBouncer) CR
- `PodMonitor` for pooler metrics
- optional managed roles/databases bootstrap job

## Install

```bash
helm install cnpg-stack oci://ghcr.io/yaelmoshi/charts/cnpg-stack --version 0.13.11
```

## Configure

Start with:

- `cnpg.cluster.storage.class`
- `cnpg.cluster.walStorage.class`
- `cnpg.cluster.imagePullSecrets`
- `cnpg.pgbouncer.image`
- `cnpg.cluster.backup.*` (if backups enabled)
- Set `cnpg.cluster.backup.endpointURL` and `cnpg.cluster.backup.destinationPath` explicitly when backups are enabled (no MinIO default is assumed)

## Notes

- `cnpg.pgbouncer.image` must contain a PgBouncer executable reachable at `/usr/bin/pgbouncer` for CNPG Pooler manager compatibility.
- This chart is publishable via `/Users/smeya/git/m0sh1.cc/helm-charts/.woodpecker/release-all.yaml` and `/Users/smeya/git/m0sh1.cc/helm-charts/.ci/publish-oci.sh`.
