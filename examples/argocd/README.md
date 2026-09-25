# ArgoCD Application Examples

These manifests use the canonical Forgejo repository and charts currently shipped
here. Commit an adapted Application to your GitOps repository and let ArgoCD
reconcile it. Review destination namespaces, project permissions, storage classes,
hostnames, and existing Secret references before enabling automated sync.

## Available examples

| Manifest | Chart | Purpose |
| --- | --- | --- |
| `example-app.yaml` | `wakapi-dhi` | Basic Application, retry policy, and values |
| `example-app-custom-values.yaml` | `wakapi-dhi` | Parameters for replicas, service, ingress, and autoscaling |
| `example-app-multi-env.yaml` | `wakapi-dhi` | Separate dev, staging, and production Applications |
| `forgejo.yaml` | `forgejo` | HTTPRoute, PostgreSQL, and optional runner |
| `forgejo-runner.yaml` | `forgejo-runner` | Registration, persistence, and registry configuration |

The generic filenames are retained for existing links; they now deploy Wakapi.
The old Gitea Runner example was removed with its retired chart.

## Prerequisites and values

ArgoCD must be installed and its project must allow the source repository and
selected destinations. These examples follow `main`; pin `targetRevision` to a
published `<chart>-v<version>` tag or commit when controlled upgrades are required.
Wakapi examples inherit the chart's packaged image defaults.

Wakapi examples need a reachable PostgreSQL database. Replace
`postgres.example.com`, database name, and user with your deployment's values.
Provision `wakapi-secrets` in each destination namespace through your secret
management workflow, with `db-password`, `password-salt`, and `cookie-key` keys.
Use a distinct database and credentials for each environment. Configure real
ingress hosts and a controller class before enabling ingress; the custom-values
example shows the fields to adapt. Horizontal autoscaling also requires cluster
metrics support.

Forgejo examples require their referenced database and runner registration
Secrets, a suitable storage class, and a Gateway matching the HTTPRoute parent.
Update the runner URL if you change the Forgejo release name or namespace.
Optional registry Secrets must exist when referenced.

## Sync behavior

`automated.selfHeal: false` disables automatic correction of live drift; Git
updates still sync automatically when `automated` is present. For manual sync,
remove the entire `automated` block and use `argocd app sync <application>` after
review. The multi-environment file contains three independent Applications.

Inspect changes before reconciliation:

```bash
argocd app get example-app
argocd app diff example-app
argocd app manifests example-app
argocd app sync example-app
argocd app wait example-app
```

## References

- [ArgoCD Helm integration](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [ArgoCD automated sync](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
