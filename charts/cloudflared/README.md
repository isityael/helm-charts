# Cloudflared Helm Chart

Helm chart for [Cloudflare Tunnel connector](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).

## Requirements

- Kubernetes >= 1.28
- A Cloudflare Tunnel with credentials JSON and certificate PEM available through Kubernetes Secrets
- Prometheus Operator CRDs when `metrics.serviceMonitor.enabled` is `true`

## Install

```bash
helm repo add sm-moshi https://sm-moshi.github.io/helm-charts
helm repo update

helm install cloudflared sm-moshi/cloudflared -n cloudflared --create-namespace -f values.yaml
```

## Configuration

The chart supports a DaemonSet by default with `replica.allNodes: true`, or a Deployment when `replica.allNodes: false`.

Use existing Secrets for tunnel material:

```yaml
tunnelConfig:
  name: example-tunnel

tunnelSecrets:
  existingSecret:
    name: cloudflared-tunnel
    credentialsKey: credentials.json
    certKey: cert.pem
```

Or split the certificate and credentials into separate Secrets:

```yaml
tunnelSecrets:
  existingPemFileSecret:
    name: cloudflared-cert
    key: cert.pem
  existingConfigJsonFileSecret:
    name: cloudflared-credentials
    key: credentials.json
```

## Values Example

```yaml
replica:
  allNodes: false
  count: 2

tunnelConfig:
  name: example-tunnel
  protocol: quic

ingress:
  - hostname: app.example.com
    service: http://app.default.svc.cluster.local:8080
  - service: http_status:404

metrics:
  service:
    enabled: true
  serviceMonitor:
    enabled: true
```

## Ingress Example

Cloudflared routes are configured through `ingress` in the tunnel config rather than Kubernetes Ingress resources:

```yaml
ingress:
  - hostname: app.example.com
    service: http://app.default.svc.cluster.local:8080
  - hostname: dashboard.example.com
    service: http://homepage.default.svc.cluster.local:3000
  - service: http_status:404
```
