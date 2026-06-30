# healthchecks

Helm chart for self-hosted Healthchecks using the official upstream image.

## Features

- External PostgreSQL configuration for CNPG or managed databases.
- Web deployment plus optional `sendalerts` worker.
- Migration init container.
- Gateway API `HTTPRoute` and Ingress support.
- Secret-friendly environment wiring.

## Install

```bash
helm install healthchecks oci://ghcr.io/isityael/charts/healthchecks --version 0.1.3
```
