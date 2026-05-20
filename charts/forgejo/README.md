# Forgejo Helm Chart

Improved public Forgejo chart for OCI distribution.

This chart wraps the upstream Forgejo Helm chart and adds m0sh1.cc defaults:

- custom `ghcr.io/yaelmoshi/forgejo` image support without the upstream `-rootless` tag suffix issue
- digest-pinned default Forgejo image
- pinned non-`latest` Helm test image
- hardened rootless security context defaults
- optional `forgejo-runner` subchart dependency for Actions runners
- public Artifact Hub metadata and schema coverage

## Requirements

- Kubernetes `>=1.28.0-0`
- External PostgreSQL is recommended for production
- Gateway API CRDs when `forgejo.httpRoute.enabled=true`
- Prometheus Operator CRDs when `forgejo.gitea.metrics.serviceMonitor.enabled=true`

## Install

```bash
helm install forgejo oci://ghcr.io/yaelmoshi/charts/forgejo --version 0.1.5
```

## Values Example

```yaml
forgejo:
  image:
    registry: ghcr.io
    repository: yaelmoshi/forgejo
    tag: "2b3887b6@sha256:f6060e8de865ee543c97689994755d43278c2750e087ed192c28b0aac5be5f07"
    rootless: true

  httpRoute:
    enabled: true
    parentRefs:
      - group: gateway.networking.k8s.io
        kind: Gateway
        name: traefik-gateway
        namespace: traefik
        sectionName: websecure
    hostnames:
      - git.example.com
    port: 3000

  gitea:
    config:
      server:
        ROOT_URL: https://git.example.com/
        DOMAIN: git.example.com
      database:
        DB_TYPE: postgres
        HOST: postgres.example.com:5432
        NAME: forgejo
        USER: forgejo
        SSL_MODE: disable
    additionalConfigFromEnvs:
      - name: FORGEJO__DATABASE__PASSWD
        valueFrom:
          secretKeyRef:
            name: forgejo-db
            key: password

runner:
  enabled: true
  namespaceOverride: forgejo-runners
  runner:
    instanceURL: http://forgejo-http.default.svc.cluster.local:3000/
    registrationTokenSecret: forgejo-runner-registration
    labels: docker:docker://ghcr.io/yaelmoshi/forgejo-job-alpine:3.23
```

## Ingress Example

```yaml
forgejo:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: git.example.com
        paths:
          - path: /
            pathType: Prefix
            port: http
    tls:
      - secretName: git-example-com-tls
        hosts:
          - git.example.com
```

## Notes

Most upstream Forgejo values are passed through under `forgejo.*`.
The optional runner is configured under `runner.*` and uses `forgejo-runner` from
`oci://ghcr.io/yaelmoshi/charts`.
