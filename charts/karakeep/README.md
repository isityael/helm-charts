# Karakeep

Deploys the m0sh1 Karakeep fork as an all-in-one web and worker container, backed by external Postgres, Meilisearch, and a browserless Chrome-compatible service.

The chart is designed for GitOps wrappers:

- `DB_DRIVER=postgres` is set by default.
- Postgres credentials can be consumed from CNPG-style secrets.
- Meilisearch is deployed by the chart unless disabled.
- Browser crawling is deployed by the chart unless disabled.
- HTTPRoute and Ingress are mutually exclusive.

## Required Secrets

Set `secretEnv.NEXTAUTH_SECRET.secretName` and `secretEnv.MEILI_MASTER_KEY.secretName` to an existing Kubernetes Secret.

For Postgres, set `database.existingSecret.name` to a secret containing `host`, `port`, `database`, `username`, and `password`, or override the key names under `database.existingSecret.keys`.
