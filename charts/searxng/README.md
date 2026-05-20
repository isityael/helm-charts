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

The generated config renderer defaults to `dhi.io/busybox:1.37.0-debian13` and the embedded
limiter backend defaults to `dhi.io/valkey:9.1.0-debian13`. Set `valkey.imagePullSecrets`
or top-level `imagePullSecrets` when the target namespace needs DHI registry credentials.
