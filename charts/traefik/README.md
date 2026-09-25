# Traefik

m0sh1 Traefik wrapper chart based on Docker's `dhi.io/traefik-chart`.

This chart keeps the upstream DHI chart as a dependency and carries the
m0sh1-specific resources that are shared by the infra wrappers:

- Gateway API integration for Traefik 3.7.x
- CrowdSec bouncer middleware
- common security headers middleware
- apex redirect and `security.txt` resources
- helper override for custom image references with an empty registry field

The embedded DHI chart values are nested under `traefik`.

## Requirements

- Kubernetes `>=1.29.0-0`
- Credentials for `dhi.io`: the Traefik chart dependency and its default
  images come from Docker Hardened Images
- Gateway API v1.5.1 Standard CRDs plus the experimental `TCPRoute` CRD,
  installed before this chart. They are intentionally managed outside this
  chart so their cluster-scoped lifecycle is independent from Traefik upgrades
  and removals.
- For `crowdsecBouncer`: a CrowdSec LAPI (and AppSec, if enabled) reachable
  from Traefik, and the bouncer API key mounted at `crowdsecBouncer.lapiKeyFile`
- For `apexRedirect` and `securityTxt`: a Gateway named `traefik-gateway` in
  the release namespace with a `websecure` listener

## Install

```bash
helm install traefik oci://ghcr.io/isityael/charts/traefik \
  --namespace traefik --create-namespace -f values.yaml
```

## Configuration

| Key | Purpose |
| --- | --- |
| `traefik.*` | Values for the DHI Traefik chart (deployment, ports, providers, Gateway API, image) |
| `crowdsecBouncer.*` | Renders the `crowdsec-bouncer` Middleware: LAPI host, scheme and key file, mode, AppSec settings, trusted client IPs |
| `securityHeaders.*` | Renders the `security-headers` Middleware (HSTS always; frame options, referrer policy and CSP when set) |
| `apexRedirect.*` | HTTPRoute that redirects `hostnames` to `hostname`; `name` keeps an existing route name |
| `securityTxt.*` | Serves `content` at `/.well-known/security.txt` for `hostnames` from an unprivileged nginx (`image`) |

Enabled apex and `security.txt` resources fail to render until their hostnames
and content are set.

## Values example

```yaml
traefik:
  deployment:
    replicas: 2
    imagePullSecrets:
      - name: kubernetes-dhi

crowdsecBouncer:
  enabled: true
  lapiHost: crowdsec-service.crowdsec.svc.cluster.local:8080
  lapiScheme: http
  lapiKeyFile: /crowdsec/api-key
  mode: stream
  updateIntervalSeconds: 60
  appsecEnabled: false
  trustedIPs:
    - 10.0.0.0/8

securityHeaders:
  referrerPolicy: same-origin
  customFrameOptionsValue: SAMEORIGIN
  contentSecurityPolicy: "frame-ancestors 'self'"

apexRedirect:
  enabled: true
  hostnames: [example.com, www.example.com]
  hostname: www.example.org

securityTxt:
  enabled: true
  hostnames: [example.com]
  content: |
    Contact: mailto:security@example.com
    Expires: 2027-01-01T12:00:00Z
```

Routes attach to the Gateway through `HTTPRoute` resources; `apexRedirect`
shows the pattern this chart uses (`parentRefs` to `traefik-gateway`,
`sectionName: websecure`).

## Upgrade notes

### 0.1.26

The `security.txt` nginx image moved from the template to
`securityTxt.image` and is pinned by digest. Override it there if you mirror
images.

### 0.1.24

Enabled apex resources now require deployment values: `apexRedirect.hostnames`,
`apexRedirect.hostname`, `securityTxt.hostnames`, and `securityTxt.content`. Set
`apexRedirect.name` to preserve an existing route name. Security text changes
trigger a pod rollout through a content checksum. The vendored DHI Traefik
dependency now matches the declared 41.6.0 lock.
