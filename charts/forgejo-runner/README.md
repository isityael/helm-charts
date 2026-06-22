# Forgejo Runner Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for [Forgejo Runner](https://forgejo.org/docs/latest/admin/actions/) with an optional Docker-in-Docker sidecar.

This chart is inspired by the upstream `forgejo-helm/forgejo-runner` chart, but keeps a smaller public
surface: digest-pinned images, no plaintext registration token value, rendered `config.yaml`, and a
non-root runner container by default.

## Requirements

- Kubernetes >= 1.28
- A Forgejo instance with Actions enabled
- A Kubernetes Secret containing a Forgejo Runner registration token, unless `runner.existingRunnerSecret` provides a pre-registered `.runner` file

## Notes

- Forgejo Runner executes remote workflow code. Treat every runner as a privileged workload boundary.
- Docker-in-Docker is enabled by default. Disable it with `dind.enabled=false` only when labels point to host/LXC execution or an external Docker endpoint.
- The runner registers itself on startup only when `/data/.runner` is missing. Enable `persistence.enabled` or provide `runner.existingRunnerSecret` to avoid re-registration after pod replacement.
- Provide registry authentication via `registryAuthSecret` and custom CA bundles via `registryCASecret`.
- Runner labels use Forgejo's `<label>:<type>://<image>` format, for example `docker:docker://ghcr.io/yaelmoshi/forgejo-job-alpine:3.23`.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| runner.image.repository | string | `ghcr.io/yaelmoshi/forgejo-runner` | Runner image repository |
| runner.image.tag | string | `12.12.0-a1a383f9@sha256:7edf0bf1125982fea00a357e4226f919ed1fd10df34d39b4494400c142363c85` | Runner image tag and digest |
| dind.enabled | bool | `true` | Enable Docker-in-Docker sidecar |
| runner.instanceURL | string | `""` | Forgejo instance URL |
| runner.registrationTokenSecret | string | `""` | Secret name holding registration token |
| runner.registrationTokenKey | string | `REGISTRATION_TOKEN` | Key in the secret for the token |
| runner.baseLabels | string | `docker:docker://ghcr.io/yaelmoshi/forgejo-job-alpine:3.23` | Default Forgejo Actions job label and image |
| runner.labels | string | `""` | Full comma-separated label set; overrides `baseLabels` composition when set |
| runner.config | object | Forgejo defaults | Rendered into `/etc/forgejo-runner/config.yaml` |
| runner.dataMountPath | string | `/data` | Runner data directory mount path |
| persistence.enabled | bool | `false` | Persist `/data`, including `.runner` and cache data, with a PVC |
| registryAuthSecret | string | `""` | Secret with `.dockerconfigjson` for registry auth |
| registryCASecret | string | `""` | Secret containing a CA bundle |
| namespaceOverride | string | `""` | Render runner resources into a namespace other than the Helm release namespace |

For full configuration options, see `values.yaml`.

## Registration Secret

```bash
kubectl create secret generic forgejo-runner-registration \
  --from-literal=REGISTRATION_TOKEN=<token>
```

## Values Example

```yaml
runner:
  instanceURL: https://forgejo.example.com
  registrationTokenSecret: forgejo-runner-registration
  registrationTokenKey: REGISTRATION_TOKEN
  name: runner-01
  labels: docker:docker://ghcr.io/yaelmoshi/forgejo-job-alpine:3.23,node22:docker://node:22-bookworm

namespaceOverride: forgejo-runners

persistence:
  enabled: true
  size: 2Gi

registryAuthSecret: forgejo-registry-auth
registryAuthMountPath: /root/.docker/config.json

registryCASecret: forgejo-registry-ca
registryCAMounts:
  - /etc/docker/certs.d/registry.example.com/ca.crt
```

## Ingress

This chart deploys only the runner and does not expose an HTTP service, so there is no Ingress example.
