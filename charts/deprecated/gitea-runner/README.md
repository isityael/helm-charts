# Gitea Runner Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for the [Gitea Actions runner](https://gitea.com/gitea/runner) with an optional Docker-in-Docker sidecar.

## Requirements

- Kubernetes >= 1.28
- A Gitea instance with Actions enabled

## Notes

- The runner requires a registration token stored in a Secret.
- Docker-in-Docker is enabled by default; disable it with `dind.enabled=false`.
- Provide registry authentication via `registryAuthSecret` and custom CA bundles via `registryCASecret`.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| runner.image.repository | string | `gitea/runner` | Runner image repository |
| runner.image.tag | string | `1.0.8@sha256:5ae0c21f365bd7cdcef7a0bdea0111b696d5dcc1bd049d600cbc989eaef95722` | Runner image tag and digest |
| dind.enabled | bool | `true` | Enable Docker-in-Docker sidecar |
| runner.instanceURL | string | `""` | Gitea instance URL |
| runner.registrationTokenSecret | string | `""` | Secret name holding registration token |
| runner.registrationTokenKey | string | `REGISTRATION_TOKEN` | Key in the secret for the token |
| runner.labels | string | `""` | Full runner label set for `GITEA_RUNNER_LABELS`; overrides `baseLabels` composition when set |
| runner.dataMountPath | string | `/data` | Runner data directory mount path |
| registryAuthSecret | string | `""` | Secret with `.dockerconfigjson` for registry auth |
| registryCASecret | string | `""` | Secret containing a CA bundle |

For full configuration options, see `values.yaml`.

## Example

```yaml
runner:
  instanceURL: https://gitea.example.com
  registrationTokenSecret: gitea-runner-secret
  registrationTokenKey: REGISTRATION_TOKEN
  name: runner-01
  labels: linux,amd64,self-hosted,alpine:docker://alpine:3.20

registryAuthSecret: gitea-registry-auth
registryAuthMountPath: /root/.docker/config.json

registryCASecret: gitea-registry-ca
registryCAMounts:
  - /etc/docker/certs.d/registry.example.com/ca.crt
```
