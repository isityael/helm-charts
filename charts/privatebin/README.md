# privatebin

Helm chart for PrivateBin encrypted paste and file sharing.

## Features

- Gateway API `HTTPRoute` and classic Ingress support.
- Persistent filesystem backend.
- Optional S3 backend for object storage such as Garage.
- Configured `conf.php` generation.
- File uploads enabled by values.
- Optional no-index `robots.txt`.
- Hardened pod and container security defaults where compatible with the upstream image.

## Install

```bash
helm install privatebin oci://ghcr.io/yaelmoshi/charts/privatebin --version 0.1.2
```
