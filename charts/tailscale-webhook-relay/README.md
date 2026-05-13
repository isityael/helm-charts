# tailscale-webhook-relay Helm Chart

Helm chart for `tailscale-webhook-relay`, a webhook relay that verifies Tailscale webhook signatures and forwards formatted notifications to ntfy.

## Requirements

- Kubernetes >= 1.28
- ntfy target URL
- Existing Secret containing `TAILSCALE_WEBHOOK_SECRET` and `NTFY_TOKEN`
- An Ingress controller or Gateway API implementation when external webhook ingress is enabled

## Install

```bash
helm repo add sm-moshi https://sm-moshi.github.io/helm-charts
helm repo update

helm install tailscale-webhook-relay sm-moshi/tailscale-webhook-relay \
  -n tailscale --create-namespace \
  --set ntfyURL=https://ntfy.example.com/tailscale-events \
  --set existingSecret=tailscale-webhook-relay
```

## Configuration

Sensitive values are not stored in chart values. Create the webhook Secret outside the chart:

```bash
kubectl -n tailscale create secret generic tailscale-webhook-relay \
  --from-literal=TAILSCALE_WEBHOOK_SECRET='<webhook-secret>' \
  --from-literal=NTFY_TOKEN='<ntfy-token>'
```

## Values Example

```yaml
ntfyURL: https://ntfy.example.com/tailscale-events
existingSecret: tailscale-webhook-relay

resources:
  requests:
    cpu: 5m
    memory: 16Mi
  limits:
    memory: 32Mi
```

## Ingress Example

```yaml
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: tailscale-webhook.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wildcard-example
      hosts:
        - tailscale-webhook.example.com
```
