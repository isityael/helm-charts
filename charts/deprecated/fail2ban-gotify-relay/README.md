# fail2ban-gotify-relay Helm Chart

Helm chart for `fail2ban-gotify-relay`, a webhook relay that forwards fail2ban-ui events to Gotify.

The chart is rendered through `bjw-s-labs/app-template`; configure workload,
service, ingress, and Gateway API values under the `app-template:` key.

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
  --set app-template.controllers.main.containers.main.env.GOTIFY_URL=http://gotify.default.svc.cluster.local \
  --set app-template.controllers.main.containers.main.env.GOTIFY_TOKEN.valueFrom.secretKeyRef.name=fail2ban-gotify-relay \
  --set app-template.controllers.main.containers.main.env.GOTIFY_TOKEN.valueFrom.secretKeyRef.key=GOTIFY_TOKEN
```

## Configuration

Sensitive values are not stored in chart values. Create the token Secret outside the chart:

```bash
kubectl -n fail2ban create secret generic fail2ban-gotify-relay \
  --from-literal=GOTIFY_TOKEN='<token>'
```

## Values Example

```yaml
app-template:
  controllers:
    main:
      containers:
        main:
          env:
            GOTIFY_URL: http://gotify.default.svc.cluster.local
            GOTIFY_TOKEN:
              valueFrom:
                secretKeyRef:
                  name: fail2ban-gotify-relay
                  key: GOTIFY_TOKEN
          resources:
            requests:
              cpu: 5m
              memory: 16Mi
            limits:
              memory: 32Mi
```

## Ingress Example

```yaml
app-template:
  ingress:
    main:
      enabled: true
      className: traefik
      hosts:
        - host: fail2ban-webhook.example.com
          paths:
            - path: /
              pathType: Prefix
              service:
                identifier: main
                port: http
      tls:
        - secretName: wildcard-example
          hosts:
            - fail2ban-webhook.example.com
```

## Migration from 0.3.x

Version `0.4.0` normalizes this chart onto `bjw-s-labs/app-template`.
Previous top-level values such as `gotifyURL`, `existingSecret`, `service`,
`ingress`, and `httpRoute` are replaced by the `app-template:` values model.

Kubernetes resource names remain release-name based, but labels/selectors follow
the app-template convention and include `app.kubernetes.io/controller: main`.
For an existing live release, plan a normal GitOps rollout review before
upgrading because Deployment selectors are immutable.
