# searxng

Helm chart for SearXNG metasearch.

## Features

- Generated `settings.yml` and `limiter.toml`.
- Optional built-in DHI Valkey for limiter state.
- Gateway API `HTTPRoute` and Ingress support.
- Persistent cache volume.
- Secret-friendly runtime secret configuration.
- Optional SearXNG theme variants generated from the bundled `simple` theme.

## Requirements

- Kubernetes `>=1.28.0-0`
- Gateway API CRDs when using `httpRoute.enabled=true`
- Registry credentials for `dhi.io` when using the embedded DHI images in a private namespace

## Install

```bash
helm install searxng oci://ghcr.io/yaelmoshi/charts/searxng --version 0.2.6
```

## Configuration

The generated config renderer defaults to `dhi.io/busybox:1.37.0-debian13` and the embedded
limiter backend defaults to `dhi.io/valkey:9.1.0-debian13@sha256:54bfadfa9596a4c24ad1879b190401310b0a767697e5ac58b198020568961b23`.
Set `valkey.imagePullSecrets` or top-level `imagePullSecrets` when the target namespace needs DHI
registry credentials.

### Theme variants

SearXNG currently ships the `simple` theme. This chart can create additional theme
entries by copying the bundled `simple` static assets and templates into new theme
directories during pod startup, then appending optional CSS overrides.

```yaml
settings:
  ui:
    defaultTheme: m0sh1-dark
    themeArgs:
      simpleStyle: dark

themes:
  enabled: true
  sourceTheme: simple
  variants:
    - name: m0sh1-dark
      cssAppend: |
        :root.theme-auto,
        :root.theme-light,
        :root.theme-dark,
        :root.theme-black {
          --color-btn-background: #3f5cff;
          --color-result-link-font: #6f8cff;
          --color-result-link-font-highlight: #6f8cff;
        }
```

## Values example

```yaml
secret:
  existingSecret: searxng-secret

settings:
  server:
    baseUrl: https://search.example.com/

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: search.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Ingress example

```yaml
ingress:
  enabled: true
  className: nginx
  annotations: {}
  hosts:
    - host: search.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: search-example-com-tls
      hosts:
        - search.example.com
```
