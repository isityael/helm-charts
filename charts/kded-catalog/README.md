# kded-catalog

Private update catalog with PostgreSQL persistence and bounded source workers.

## Requirements

Kubernetes >=1.28, an existing PostgreSQL database and dedicated basic-auth Secret,
the PostgreSQL CA certificate Secret, and a dedicated API bearer-token Secret. Tailscale Kubernetes operator and Cilium
are required when their integrations are enabled. The optional browser requires
an explicit persistent StorageClass and a catalogue image containing `/catalog-egress`.

## Install

This chart is published to Forgejo at
`oci://git.m0sh1.cc/m0sh1-internal/charts/kded-catalog`.
Authenticate Helm to `git.m0sh1.cc` using the existing package registry credential
through `--password-stdin` before retrieving it. KDED releases use Forgejo;
the shared repository's GHCR publication route is excluded for this chart.

Publish and verify an immutable application image, then provide its real digest
in `image.spec` and set `enabled=true`. The chart defaults to disabled and refuses
unpinned enabled images. Install using the infrastructure GitOps workflow.

## Configuration

`postgres.existingSecret` must contain `username` and `password`. Only `ca.crt`
from `postgres.caSecret` is mounted; connections require hostname verification.
`auth.existingSecret` must contain a cryptographically random `token` of at least
32 bytes. It is mounted read-only at `/run/secrets/api/token` and supplied via
`AUTH_TOKEN_FILE`; tokens are never included in values or environment variables.
Mutating POST endpoints require bearer authentication in addition to private ingress.
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

## Persistent browser

`browser.enabled` provisions one headful official Selenium Firefox pod, a 2Gi
profile PVC and a separate validating CONNECT proxy using the catalogue image.
The Firefox image is pinned by digest, runs as UID 1200/GID 1201, drops all
capabilities and is configured to retain RuntimeDefault seccomp and the Firefox
content sandbox. Runtime sandbox verification is required before API integration.
Generated Selenium/X11 configuration and the desktop home use bounded ephemeral
temporary storage with a read-only root filesystem. The persistent profile is `/home/seluser/profile`;
only one pod runs, with Recreate updates. Shared memory is capped at 1Gi.

The PVC is excluded from Velero, protected against automatic prune/deletion and
retained until explicitly destroyed. Treat it as credential storage; it is not
part of catalogue metadata exports. Choose a ZFS StorageClass with Retain policy
in the root wrapper. Destroying the retained PVC/PV/dataset requires explicit
operational action; disabling the feature does not erase login state.

Browser and proxy policies are mandatory. Browser DNS can resolve only its proxy
Service; its only application egress is TCP 3128 to that proxy. The proxy resolves
only `browser.egressHosts` and can connect to those exact names on 443, with public
IP validation and pinned dialing enforced by `/catalog-egress`. Initially only
the approved source hosts and `challenges.cloudflare.com` are listed; approve observed static-resource names
explicitly. WebDriver 4444 and noVNC 7900 accept only catalogue API pods. Raw VNC
5900 has no Service or policy ingress. Desktop authentication is enforced by the
Rust API; VNC password authentication is disabled only inside the isolated pod.

Provision with `browser.enabled=true` and `browser.apiIntegration=false` first.
Verify actual Firefox content sandbox, profile ownership/persistence, blocked
direct/private/unapproved egress and private desktop access before enabling
`browser.apiIntegration`. Integration sets all three `KDED_BROWSER_*` variables
together and requires `browser.publicOrigin` to be the tailnet HTTPS origin.
The existing Tailscale Ingress continues to route only to the Rust API.

The temporary volume also covers the image's fixed `/var/log/supervisor` log
directory so Xvfb, VNC and noVNC can start with a read-only root filesystem.
Startup and readiness require the X11 Unix socket selected by `DISPLAY_NUM`, a
VNC RFB greeting and successful WebDriver/noVNC HTTP responses.
`browser.podAnnotations` accepts string annotations for declarative browser pod
rollouts, including profile-persistence validation. The mandatory profile backup
exclusion takes precedence over a conflicting custom annotation.
