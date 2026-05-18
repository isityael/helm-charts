# searxng

Helm chart for SearXNG metasearch.

## Features

- Generated `settings.yml` and `limiter.toml`.
- Optional built-in DHI Valkey for limiter state.
- Gateway API `HTTPRoute` and Ingress support.
- Persistent cache volume.
- Secret-friendly runtime secret configuration.

## Install

```bash
helm install searxng oci://ghcr.io/yaelmoshi/charts/searxng --version 0.1.6
```

## Configuration

The embedded limiter backend defaults to `dhi.io/valkey:9.0.4`. Set `valkey.imagePullSecrets`
or top-level `imagePullSecrets` when the target namespace needs DHI registry credentials.
