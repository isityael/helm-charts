---
title: "cinny"

description: "A Helm Chart to install cinny (yet another matrix client)"

---

# cinny

![Version: 0.2.23](https://img.shields.io/badge/Version-0.2.23-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.12.3](https://img.shields.io/badge/AppVersion-4.12.3-informational?style=flat-square)

A Helm Chart to install cinny (yet another matrix client)

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| WrenIX |  | <https://wrenix.eu> |

## Usage

Helm must be installed and setup to your kubernetes cluster to use the charts.
Refer to Helm's [documentation](https://helm.sh/docs) to get started.
Once Helm has been set up correctly, fetch the charts as follows:

```bash
helm pull oci://codeberg.org/wrenix/helm-charts/cinny
```

You can install a chart release using the following command:

```bash
helm install cinny-release oci://codeberg.org/wrenix/helm-charts/cinny --values values.yaml
```

To uninstall a chart release use `helm`'s delete command:

```bash
helm uninstall cinny-release
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| config.allowCustomHomeservers | bool | `true` |  |
| config.defaultHomeserver | int | `2` |  |
| config.featuredCommunities.openAsDefault | bool | `false` |  |
| config.featuredCommunities.rooms[0] | string | `"#cinny:matrix.org"` |  |
| config.featuredCommunities.rooms[1] | string | `"#freesoftware:matrix.org"` |  |
| config.featuredCommunities.rooms[2] | string | `"#pcapdroid:matrix.org"` |  |
| config.featuredCommunities.rooms[3] | string | `"#gentoo:matrix.org"` |  |
| config.featuredCommunities.rooms[4] | string | `"#PrivSec.dev:arcticfoxes.net"` |  |
| config.featuredCommunities.rooms[5] | string | `"#disroot:aria-net.org"` |  |
| config.featuredCommunities.servers[0] | string | `"envs.net"` |  |
| config.featuredCommunities.servers[1] | string | `"matrix.org"` |  |
| config.featuredCommunities.servers[2] | string | `"monero.social"` |  |
| config.featuredCommunities.servers[3] | string | `"mozilla.org"` |  |
| config.featuredCommunities.spaces[0] | string | `"#cinny-space:matrix.org"` |  |
| config.featuredCommunities.spaces[1] | string | `"#community:matrix.org"` |  |
| config.featuredCommunities.spaces[2] | string | `"#space:envs.net"` |  |
| config.featuredCommunities.spaces[3] | string | `"#science-space:matrix.org"` |  |
| config.featuredCommunities.spaces[4] | string | `"#libregaming-games:tchncs.de"` |  |
| config.featuredCommunities.spaces[5] | string | `"#mathematics-on:matrix.org"` |  |
| config.hashRouter.basename | string | `"/"` |  |
| config.hashRouter.enabled | bool | `false` |  |
| config.homeserverList[0] | string | `"converser.eu"` |  |
| config.homeserverList[1] | string | `"envs.net"` |  |
| config.homeserverList[2] | string | `"matrix.org"` |  |
| config.homeserverList[3] | string | `"monero.social"` |  |
| config.homeserverList[4] | string | `"mozilla.org"` |  |
| config.homeserverList[5] | string | `"xmr.se"` |  |
| fullnameOverride | string | `""` |  |
| global.image.pullPolicy | string | `nil` | if set it will overwrite all pullPolicy |
| global.image.registry | string | `nil` | if set it will overwrite all registry entries |
| image.pullPolicy | string | `"IfNotPresent"` | This sets the pull policy for images. (could be overwritten by global.image.pullPolicy) |
| image.registry | string | `"ghcr.io"` | image registry (could be overwritten by global.image.registry) |
| image.repository | string | `"cinnyapp/cinny"` | image repository |
| image.tag | string | `""` | image tag - Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| networkPolicy.egress.enabled | bool | `true` | activate egress no networkpolicy |
| networkPolicy.egress.extra | list | `[]` | egress rules |
| networkPolicy.enabled | bool | `false` |  |
| networkPolicy.ingress.http | list | `[]` | ingress for http port (e.g. ingress-controller) |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| replicaCount | int | `1` | replicas |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

Autogenerated from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs)
