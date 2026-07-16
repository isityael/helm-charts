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
