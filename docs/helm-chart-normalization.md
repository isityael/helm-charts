# Helm Chart Normalization

This repository uses a tiered chart normalization policy instead of forcing every
chart through one generic renderer.

## Default chart model

Use `bjw-s-labs/app-template` for simple application charts whose rendered
surface is primarily:

- Deployment, Service, ServiceAccount
- HTTPRoute or Ingress
- PVC, ConfigMap, Secret
- probes, resources, pod security context, scheduling knobs
- optional ServiceMonitor or VMServiceScrape when the generic chart can express
  them cleanly

Do not use Stakater `application` as the repo default. It is useful for single
stateless applications, but it is too narrow for multi-workload app stacks and
pushes too much into raw escape hatches.

Do not use Nixys `nxs-universal-chart` as the repo default. It can model keyed
multi-workload charts, but it brings a broad optional platform dependency tree
that does not fit this repository's lean public OCI chart model.

## Keep bespoke

Keep charts bespoke when their primary value is custom CRDs, RBAC-heavy
controllers, upstream chart wrapping, dependency patching, or multi-component
operator stacks. Current examples:

- `csi-driver-nfs`
- `proxmox-csi-plugin`
- `cnpg-stack`
- `matrix-umbrella`
- `forgejo`
- `traefik`
- `m0sh1-exporter`
- `cloudflared`, unless a future pilot proves the observability resources
  remain clean through `app-template`

## Migration rule

Migrate one chart at a time. For each migration:

1. Bump the chart version according to the compatibility impact.
2. Render the old chart and the migrated chart.
3. Compare object names, selectors, ports, routes, service accounts, security
   contexts, probes, resources, and scheduling fields.
4. Commit `Chart.lock` and vendored `charts/*.tgz` when a dependency is added.
5. Update public documentation with any values contract change.

Helm does not dynamically translate old parent chart values into a subchart's
values. A chart converted to `app-template` must expose the bjw-s values under
the dependency key, usually `app-template:`.

## Pilot result

`fail2ban-gotify-relay` is the first pilot chart. The migration preserves object
names, service port, image reference, environment variables, resources, pod
security context, probes, and scheduling defaults. The migration is still a
breaking chart version because `app-template` owns the standard labels and adds
`app.kubernetes.io/controller: main` to selectors.

Do not bulk-migrate the next charts until each consumer has an explicit rollout
plan for immutable selector changes and the new `app-template:` values contract.
