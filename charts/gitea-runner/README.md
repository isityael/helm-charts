# Gitea Runner Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/m0sh1-helm-charts)](https://artifacthub.io/packages/search?repo=m0sh1-helm-charts)

Helm chart for the [Gitea Actions runner](https://gitea.com/gitea/act_runner) with an optional Docker-in-Docker sidecar, using the `bjw-s/common` library.

## Requirements

- Kubernetes >= 1.28
- A Gitea instance with Actions enabled

## Notes

- The runner requires a registration token stored in a Secret.
- Docker-in-Docker is enabled by default; disable it by setting `controllers.main.containers.dind.enabled=false`.
- Provide registry authentication via `registryAuthSecret` and custom CA bundles via `registryCASecret`.

## Values (overview)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| controllers.main.containers.runner.image.repository | string | `gitea/act_runner` | Runner image repository |
| controllers.main.containers.runner.image.tag | string | `0.2.13` | Runner image tag |
| controllers.main.containers.dind.enabled | bool | `true` | Enable Docker-in-Docker sidecar |
| runner.instanceURL | string | `""` | Gitea instance URL |
| runner.registrationTokenSecret | string | `""` | Secret name holding registration token |
| runner.registrationTokenKey | string | `REGISTRATION_TOKEN` | Key in the secret for the token |
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
  baseLabels: self-hosted
  jobLabel: alpine
  jobImage: alpine:3.20

registryAuthSecret: gitea-registry-auth
registryAuthMountPath: /root/.docker/config.json

registryCASecret: gitea-registry-ca
registryCAMounts:
  - /etc/docker/certs.d/registry.example.com/ca.crt
```
