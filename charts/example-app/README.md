# Example Application Helm Chart

This is an example Helm chart that demonstrates the basic structure and components of a Kubernetes application deployment using Helm.

## Overview

This chart deploys a sample application with the following components:
- Deployment
- Service
- Ingress (optional)
- ServiceAccount
- HorizontalPodAutoscaler (optional)

## Installation

### Using Helm CLI

```bash
# Install with default values
helm install my-example-app ./charts/example-app

# Install with custom values
helm install my-example-app ./charts/example-app --values custom-values.yaml

# Install in a specific namespace
helm install my-example-app ./charts/example-app --namespace my-namespace --create-namespace
```

### Using ArgoCD

Create an ArgoCD Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: example-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<username>/helm-charts'
    path: charts/example-app
    targetRevision: main
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Configuration

The following table lists the configurable parameters and their default values.

### Common Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `nginx` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag | `""` (uses appVersion from Chart.yaml) |
| `nameOverride` | Override the chart name | `""` |
| `fullnameOverride` | Override the full name | `""` |

### Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.hosts` | Ingress hosts configuration | `[]` |
| `ingress.tls` | Ingress TLS configuration | `[]` |

### Autoscaling Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `100` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |

### Resource Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | Not set |
| `resources.limits.memory` | Memory limit | Not set |
| `resources.requests.cpu` | CPU request | Not set |
| `resources.requests.memory` | Memory request | Not set |

## Examples

### Install with custom image

```bash
helm install my-app ./charts/example-app \
  --set image.repository=my-registry/my-app \
  --set image.tag=v1.0.0
```

### Enable ingress

```bash
helm install my-app ./charts/example-app \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=example.local \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

### Enable autoscaling

```bash
helm install my-app ./charts/example-app \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10
```

## Upgrading

```bash
# Upgrade to a new version
helm upgrade my-app ./charts/example-app

# Upgrade with new values
helm upgrade my-app ./charts/example-app --values new-values.yaml
```

## Uninstalling

```bash
helm uninstall my-app
```

## Customization

This is an example chart. To use it as a template for your own application:

1. Copy the `example-app` directory to a new directory with your app name
2. Update `Chart.yaml` with your application details
3. Modify `values.yaml` with your default configuration
4. Update templates in the `templates/` directory as needed
5. Add any additional Kubernetes resources your application requires
6. Update this README with your application-specific documentation

## Testing

```bash
# Lint the chart
helm lint ./charts/example-app

# Dry-run installation
helm install test ./charts/example-app --dry-run --debug

# Template rendering
helm template test ./charts/example-app
```
