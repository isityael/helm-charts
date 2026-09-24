# Matrix Umbrella

DHI-first umbrella chart for a Matrix homeserver stack.

The chart composes:

- Element ESS `matrix-stack` for Synapse, Matrix Authentication Service, Element Web, and well-known delegation
- Cinny
- mautrix Discord, Signal, Telegram, and WhatsApp bridge dependencies
- matrix-appservice-irc

## Install

```bash
helm install matrix oci://ghcr.io/isityael/charts/matrix-umbrella -f values.yaml
```

## Image Policy

Defaults use Docker Hardened Images where a compatible generic image exists.
Matrix-specific runtimes without DHI-compatible replacements use upstream
images and are exposed in `values.yaml` so Renovate can track them.
The generic DHI defaults currently include HAProxy, PostgreSQL, Valkey, and
helper images.

If you do not have DHI access, use:

```bash
helm install matrix oci://ghcr.io/isityael/charts/matrix-umbrella \
  -f upstream-images-values.yaml \
  -f values.yaml
```

## Production Profile

The default profile expects external PostgreSQL and Redis-compatible storage.
Set:

- `ess.synapse.postgres`
- `ess.matrixAuthenticationService.postgres`
- `ess.synapse.redis`
- `ess.synapse.media.storage`
- ingress hosts for Synapse, Element Web, and well-known delegation

Public registration is disabled by default.

## Bridges

Bridge dependencies are disabled by default. Enable each bridge only after
creating its external database credentials and appservice registration wiring.
Synapse consumes bridge registration files through `ess.synapse.appservices`.
For GitOps deployments, pre-create each mautrix bridge Secret and set
`mautrix-<bridge>.existingSecret.name`. The Secret must contain `config.yaml`
and `registration.yaml`; the chart will mount those files and will not render a
generated bridge Secret.

`matrix-appservice-irc` is vendored but disabled by default. Its upstream chart
currently has a strict values schema that rejects Helm's injected `global` map
when used as an enabled dependency. Enable it only with Helm schema validation
disabled or after the upstream chart schema allows `global`.

## Examples

- `examples/dhi-values.yaml` keeps DHI image defaults and shows pull secret wiring.
- `examples/upstream-images-values.yaml` switches optional generic helper images to public upstream images.
- `ci/test-values.yaml` is the repository render/lint fixture.
