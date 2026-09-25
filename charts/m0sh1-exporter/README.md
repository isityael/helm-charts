# m0sh1-exporter

Network exporter bundle for m0sh1.cc infrastructure. The chart deploys the
local OPNsense exporter wrapper and vendors upstream charts for SNMP and
Proxmox VE exporter integrations.

## Requirements

- Kubernetes `>=1.28`
- Helm `>=3.8` for OCI workflows
- Existing OPNsense API credential Secret when `opnsenseExporter` is enabled
- Prometheus Operator or VictoriaMetrics Operator when the matching scrape
  resources are enabled

## Install

```bash
helm install m0sh1-exporter oci://ghcr.io/isityael/charts/m0sh1-exporter \
  --namespace monitoring \
  --create-namespace
```

## Configuration

| Key | Purpose |
| --- | --- |
| `opnsenseExporter.*` | OPNsense exporter: image, OPNsense address and API Secret, Service port, ServiceMonitor/VMServiceScrape, resources |
| `snmpExporter.*` | Values for the upstream `prometheus-snmp-exporter` chart |
| `pveexporter.*` | Values for the upstream `prometheus-pve-exporter` chart |
| `serviceAccount.*`, `podSecurityContext`, `nodeSelector`, `podAnnotations` | Pod settings for the OPNsense exporter |
| `tests.*` | Helm test pod |

## Values Example

```yaml
opnsenseExporter:
  opnsense:
    address: opnsense.example.com
    existingSecret: opnsense-exporter-api
    apiKeyKey: api-key
    apiSecretKey: api-secret
  serviceMonitor:
    enabled: true
    additionalLabels:
      release: kube-prometheus-stack

snmpExporter:
  serviceMonitor:
    enabled: true
    module:
      - if_mib
    auth:
      - public_v2

pveexporter:
  env:
    pveExistingSecretName: monitoring-pve-exporter
  serviceMonitor:
    enabled: true
```

## Secrets

The chart expects credentials to be supplied through existing Kubernetes
Secrets. Do not put OPNsense or Proxmox tokens directly into values files.

## Observability

The chart supports Prometheus `ServiceMonitor` resources and VictoriaMetrics
`VMServiceScrape` resources. Enable only the scrape type used by the target
cluster.

## Tests

`helm test <release>` runs a pod that fetches the OPNsense exporter's `/metrics`, which also proves the exporter can reach the OPNsense API. Disable it with
`tests.enabled=false`. Argo CD ignores Helm test hooks, so GitOps syncs never
create the pod.
