# Argus Helm Chart

Helm chart for [Release-Argus](https://github.com/release-argus/Argus).

## Requirements

- Kubernetes >= 1.28
- An Ingress controller or Gateway API implementation (optional)

## Notes

- Argus reads its config from `/config/config.yml` (mounted from a ConfigMap by default).
- Set `config.raw` to provide the full YAML string, or use `config.data` for a structured map.
- Secrets are not stored in this repo. Provide them via an existing Secret or create one at install time.
- You can keep the `service` block in a separate file and load it with `config.serviceFromFile`.
- Optional: enable auto-icons for services with `config.autoIcons.enabled`.

## Install

```bash
helm repo add yaelmoshi https://yaelmoshi.github.io/helm-charts
helm repo update

helm install argus yaelmoshi/argus -n argus --create-namespace
```

## Configuration

### Inline config values

```yaml
config:
  data:
    settings:
      web:
        listen_addr: 0.0.0.0
        listen_port: 8080
    notify:
      discord_main:
        type: discord
        url_fields:
          Token: ${ARGUS_DISCORD_TOKEN}
          WebhookID: ${ARGUS_DISCORD_WEBHOOK_ID}
    service:
      example_release:
        comment: "Monitor an upstream release"
        options:
          active: true
          interval: 1h
        latest_version:
          type: github
          url: owner/repo
        notify:
          discord_main: {}
```

### Split service block into a separate file

Create a file (example included at `config/service.example.yaml`) and load it with `--set-file`:

```bash
helm install argus yaelmoshi/argus \
  --set-file config.serviceFromFile=charts/argus/config/service.example.yaml
```

Or in a values file:

```yaml
config:
  serviceFromFile: |
    service:
      example_release:
        options:
          active: true
```

### Auto icons (opt-in)

```yaml
config:
  autoIcons:
    enabled: true
    github: true
    webFavicon: true
```

### Use an existing Secret for Discord

```yaml
secret:
  existingSecret: argus-discord-webhook
  envFrom: true
```

### Create a Secret at install time (do not commit secrets)

```yaml
secret:
  create: true
  envFrom: true
  stringData:
    ARGUS_DISCORD_TOKEN: "<token>"
    ARGUS_DISCORD_WEBHOOK_ID: "<webhook-id>"
```

### Use an existing ConfigMap

```yaml
config:
  useExistingConfigMap: argus-config
```

### Common chart overrides

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

## Ingress example

```yaml
ingress:
  enabled: true
  className: traefik
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
  hosts:
    - host: argus.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wildcard-example
      hosts:
        - argus.example.com
```

## Gateway API example

```yaml
ingress:
  enabled: false
  hosts:
    - host: argus.example.com
      paths:
        - path: /
          pathType: Prefix

httpRoute:
  enabled: true
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: traefik-gateway
      namespace: traefik
      sectionName: websecure
  hostnames:
    - argus.example.com
```
