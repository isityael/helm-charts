# Youtarr Helm Chart

Public Helm chart for [Youtarr](https://github.com/DialmasterOrg/Youtarr), a
self-hosted YouTube downloader that writes media and metadata for media servers.

The embedded database defaults to Docker Hardened Images MariaDB. Clusters that
cannot pull from `dhi.io` can use `examples/non-dhi-values.yaml` or configure an
external MariaDB/MySQL service.

## Install

```bash
helm install youtarr oci://ghcr.io/isityael/charts/youtarr --version 0.1.0
```

With non-DHI embedded MariaDB:

```bash
helm install youtarr oci://ghcr.io/isityael/charts/youtarr \
  --version 0.1.0 \
  -f examples/non-dhi-values.yaml
```

## Authentication

`auth.enabled` defaults to `true`. If no preset auth secret is configured,
Youtarr uses its one-time setup flow. To inject preset credentials, create a
Secret and set `auth.presetExistingSecret.name`.

## Database

`database.type` defaults to `embedded`, which deploys a single DHI MariaDB
StatefulSet using:

```yaml
mariadb:
  image:
    repository: dhi.io/mariadb
    tag: 12.3.2-debian13
    digest: sha256:9378d3cd184a741d9664d37ad3bdc5729fd7131ff06bb09b7188b6df7b33b3de
```

The chart creates MariaDB credentials at install time unless
`mariadb.auth.existingSecret.name` is set. For external MariaDB/MySQL, set
`database.type=external` and provide `externalDatabase.existingSecret.name`.

## Persistence

The chart exposes four Youtarr volumes:

| Value | Mount path | Default size |
|-------|------------|--------------|
| `persistence.downloads` | `/usr/src/app/data` | `20Gi` |
| `persistence.config` | `/app/config` | `1Gi` |
| `persistence.jobs` | `/app/jobs` | `1Gi` |
| `persistence.images` | `/app/server/images` | `5Gi` |

`persistence.downloads.hostPath` is available for deployments that intentionally
write downloads to a node-local media path. PVCs are the default.

## Values

| Value | Default | Description |
|-------|---------|-------------|
| `replicaCount` | `1` | Number of Youtarr pods |
| `revisionHistoryLimit` | `2` | Deployment revision history limit |
| `strategy` | `{}` | Optional Deployment update strategy |
| `image.repository` | `docker.io/dialmaster/youtarr` | Youtarr image repository |
| `image.tag` | `v1.72.1` | Youtarr image tag |
| `image.digest` | `""` | Optional Youtarr image digest |
| `imagePullSecrets` | `[]` | Pull secrets for the Youtarr pod |
| `auth.enabled` | `true` | Enable Youtarr authentication |
| `auth.presetExistingSecret.name` | `""` | Existing Secret with preset credentials |
| `configOverrides` | `{}` | Values merged into `/app/config/config.json` before Youtarr starts |
| `configSecretOverrides` | `{}` | Secret-backed values merged into `/app/config/config.json` before Youtarr starts. Values are JSON-decoded when possible, otherwise used as strings |
| `database.type` | `embedded` | `embedded` or `external` |
| `mariadb.enabled` | `true` | Deploy embedded MariaDB when `database.type=embedded` |
| `mariadb.image.repository` | `dhi.io/mariadb` | Embedded MariaDB image repository |
| `mariadb.image.tag` | `12.3.2-debian13` | Embedded MariaDB image tag |
| `mariadb.image.digest` | `sha256:9378...b3de` | Embedded MariaDB OCI index digest |
| `mariadb.imagePullSecrets` | `[]` | Pull secrets for embedded MariaDB |
| `externalDatabase.host` | `""` | External MariaDB/MySQL host |
| `externalDatabase.port` | `3306` | External MariaDB/MySQL port |
| `externalDatabase.existingSecret.name` | `""` | Secret containing external DB password |
| `service.port` | `80` | Kubernetes Service port |
| `service.containerPort` | `3011` | Youtarr container port |
| `ingress.enabled` | `false` | Create a Kubernetes Ingress |
| `httpRoute.enabled` | `false` | Create a Gateway API HTTPRoute |
| `extraEnv` | `[]` | Extra environment variables for Youtarr |

## Notes

- Only one of `ingress.enabled` or `httpRoute.enabled` may be true.
- PostgreSQL/CNPG is intentionally not supported because Youtarr expects
  MariaDB/MySQL.
- No plaintext passwords are stored in chart values.
