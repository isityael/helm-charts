# fail2ban-gotify-relay Helm Chart

Helm chart for `fail2ban-gotify-relay`, a webhook relay that forwards fail2ban-ui events to Gotify.

## Requirements

- Kubernetes >= 1.28
- Gotify server URL
- Existing Secret containing a `GOTIFY_TOKEN` key
- An Ingress controller or Gateway API implementation when external webhook ingress is enabled

## Install

```bash
helm repo add yaelmoshi https://yaelmoshi.github.io/helm-charts
helm repo update

helm install fail2ban-gotify-relay yaelmoshi/fail2ban-gotify-relay \
  -n fail2ban --create-namespace \
  --set gotifyURL=http://gotify.default.svc.cluster.local \
  --set existingSecret=fail2ban-gotify-relay
```

## Configuration

Sensitive values are not stored in chart values. Create the token Secret outside the chart:

```bash
kubectl -n fail2ban create secret generic fail2ban-gotify-relay \
  --from-literal=GOTIFY_TOKEN='<token>'
```

## Values Example

```yaml
gotifyURL: http://gotify.default.svc.cluster.local
existingSecret: fail2ban-gotify-relay

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
    - host: fail2ban-webhook.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wildcard-example
      hosts:
        - fail2ban-webhook.example.com
```
