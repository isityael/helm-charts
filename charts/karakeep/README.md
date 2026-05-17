# Karakeep

Deploys the m0sh1 Karakeep fork as an all-in-one web and worker container, backed by external Postgres, Meilisearch, and a browserless Chrome-compatible service.

The chart is designed for GitOps wrappers:

- `DB_DRIVER=postgres` is set by default.
- Postgres credentials can be consumed as a full `DATABASE_URL` or as discrete
  `POSTGRES_*` values.
- Meilisearch is deployed by the chart unless disabled.
- Browser crawling is deployed by the chart unless disabled.
- HTTPRoute and Ingress are mutually exclusive.
- `hostAliases` can be set for split-horizon DNS cases such as in-cluster OIDC discovery.

## Required Secrets

Set `secretEnv.NEXTAUTH_SECRET.secretName` and `secretEnv.MEILI_MASTER_KEY.secretName` to an existing Kubernetes Secret.

For Postgres, either:

- set `database.url` directly;
- set `database.existingSecret.name` and `database.existingSecret.keys.url` to
  consume a full connection URI from a secret key such as CNPG's `uri`; or
- set `database.existingSecret.name` to a secret containing `host`, `port`,
  `database`, `username`, and `password`, overriding the key names under
  `database.existingSecret.keys` when needed.

## Meilisearch Upgrades

The chart can pass startup arguments to the managed Meilisearch container with
`meilisearch.args`.

Meilisearch data directories are version-sensitive. If an existing PVC was
created by an older Meilisearch release, do not only change
`meilisearch.image.tag`. Follow Meilisearch's migration guide first. For
supported v1.x upgrades, create a snapshot, then run the new image once with:

```yaml
meilisearch:
  image:
    tag: "v1.43.1@sha256:4407d9f9a4a5b8ef2e382827782b3dd6e0ecf8f2832ecb0344601691c13da149"
  args:
    - --experimental-dumpless-upgrade
```

After the `UpgradeDatabase` task succeeds, remove the migration argument in a
follow-up deployment and keep the upgraded image tag.
