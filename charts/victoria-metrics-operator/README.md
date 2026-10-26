# VictoriaMetrics operator release snapshot

This package pairs operator v0.75.1 with its matching CRDs from upstream commit
`1f142a2b5e3e43e3667aa1b2cda86067457b0c1e`. It preserves upstream values and deployment templates.
The published upstream 0.68.1 archive still packages v0.75.0; this separately versioned snapshot
closes that release gap without changing the infra wrapper contract. Return to a matching
official release once available. CRD YAML formatting changes are verified to preserve parsed content.

## Install

```sh
helm install victoria-metrics-operator oci://git.m0sh1.cc/isityael/charts/victoria-metrics-operator --version 0.68.1-yael.1
```

## Configuration example

```yaml
fullnameOverride: victoria-metrics-operator
watchNamespaces: []
```

No ingress is required for this controller. Upstream requirements and values follow.

# VictoriaMetrics Operator Helm chart

Chart documentation is available [here](https://docs.victoriametrics.com/helm/victoria-metrics-operator/).
Changelog is [here](https://docs.victoriametrics.com/helm/victoria-metrics-operator/changelog/).
