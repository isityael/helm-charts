# Traefik

m0sh1 Traefik wrapper chart based on Docker's `dhi.io/traefik-chart`.

This chart keeps the upstream DHI chart as a dependency and carries the
m0sh1-specific resources that are shared by the infra wrappers:

- Gateway API integration for Traefik 3.7.x; install the Gateway API v1.5.1
  Standard CRDs plus the experimental TCPRoute CRD before deploying this chart
- CrowdSec bouncer middleware
- common security headers middleware
- apex redirect and `security.txt` resources
- helper override for custom image references with an empty registry field

The embedded DHI chart values are nested under `traefik`.

Gateway API CRDs are intentionally managed outside this chart so their
cluster-scoped lifecycle is independent from Traefik upgrades and removals.

### Upgrade to 0.1.24

Enabled apex resources now require deployment values: `apexRedirect.hostnames`,
`apexRedirect.hostname`, `securityTxt.hostnames`, and `securityTxt.content`. Set
`apexRedirect.name` to preserve an existing route name. Security text changes
trigger a pod rollout through a content checksum. The vendored DHI Traefik
dependency now matches the declared 41.6.0 lock.
