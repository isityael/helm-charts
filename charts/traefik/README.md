# Traefik

m0sh1 Traefik wrapper chart based on Docker's `dhi.io/traefik-chart`.

This chart keeps the upstream DHI chart as a dependency and carries the
m0sh1-specific resources that are shared by the infra wrappers:

- Gateway API TCPRoute/TLSRoute experimental CRDs used by Traefik 3.7.x
- CrowdSec bouncer middleware
- common security headers middleware
- apex redirect and `security.txt` resources
- helper override for custom image references with an empty registry field

The embedded DHI chart values are nested under `traefik`.
