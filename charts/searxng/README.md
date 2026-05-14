# searxng

Helm chart for SearXNG metasearch.

## Features

- Generated `settings.yml` and `limiter.toml`.
- Optional built-in Valkey for limiter state.
- Gateway API `HTTPRoute` and Ingress support.
- Persistent cache volume.
- Secret-friendly runtime secret configuration.

## Install

```bash
helm install searxng oci://ghcr.io/sm-moshi/charts/searxng --version 0.1.0
```
