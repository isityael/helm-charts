# ArgoCD Application Examples

This directory contains example ArgoCD Application manifests demonstrating different patterns for deploying Helm charts from this repository.

## Prerequisites

- ArgoCD installed in your Kubernetes cluster
- kubectl configured to access your cluster
- Appropriate RBAC permissions to create Applications in the `argocd` namespace

## Examples

### 1. Basic Application (`example-app.yaml`)

A comprehensive example showing all common configuration options for deploying a Helm chart with ArgoCD.

```bash
kubectl apply -f examples/argocd/example-app.yaml
```

**Features:**

- Automated sync with prune and self-heal enabled
- Namespace auto-creation
- Retry configuration for failed syncs
- Comprehensive comments explaining each option

### 2. Homepage (`homepage.yaml`)

Example showing how to deploy the Homepage chart and set the required `HOMEPAGE_ALLOWED_HOSTS`.

```bash
kubectl apply -f examples/argocd/homepage.yaml
```

**Features:**

- Sets required `HOMEPAGE_ALLOWED_HOSTS`
- Optional ingress values shown (disabled by default)

### 3. IT-Tools (`it-tools.yaml`)

Example showing how to deploy the IT-Tools chart.

```bash
kubectl apply -f examples/argocd/it-tools.yaml
```

**Features:**

- Optional ingress values shown (disabled by default)

### 4. CyberChef (`cyberchef.yaml`)

Example showing how to deploy the CyberChef chart.

```bash
kubectl apply -f examples/argocd/cyberchef.yaml
```

**Features:**

- Optional ingress values shown (disabled by default)
### 6. WUD (`wud.yaml`)

Example showing how to deploy the WUD chart.

```bash
kubectl apply -f examples/argocd/wud.yaml
```

**Features:**

- Optional ingress values shown (disabled by default)
- `envFromSecret` example

### 7. Gitea Runner (`gitea-runner.yaml`)

Example showing how to deploy the Gitea runner chart.

```bash
kubectl apply -f examples/argocd/gitea-runner.yaml
```

**Features:**

- Runner registration settings
- Optional registry auth and CA examples

### 8. Forgejo (`forgejo.yaml`)

Example showing how to deploy the improved Forgejo chart with the optional Forgejo runner dependency.

```bash
kubectl apply -f examples/argocd/forgejo.yaml
```

**Features:**

- Custom `ghcr.io/isityael/forgejo` image defaults
- Gateway API `HTTPRoute` example
- External PostgreSQL secret wiring
- Optional runner dependency values

### 9. Forgejo Runner (`forgejo-runner.yaml`)

Example showing how to deploy the Forgejo runner chart.

```bash
kubectl apply -f examples/argocd/forgejo-runner.yaml
```

**Features:**

- Forgejo Runner registration settings
- Digest-pinned runner image defaults
- Optional persistence, registry auth, and CA examples

### 10. Custom Values (`example-app-custom-values.yaml`)

Demonstrates how to override default chart values using ArgoCD parameters.

```bash
kubectl apply -f examples/argocd/example-app-custom-values.yaml
```

**Features:**

- Custom replica count
- Custom image tag
- LoadBalancer service type
- Ingress and autoscaling enabled
- Multiple value override methods shown

### 11. Multi-Environment (`example-app-multi-env.yaml`)

Shows the "App of Apps" pattern for managing multiple environments.

```bash
kubectl apply -f examples/argocd/example-app-multi-env.yaml
```

**Features:**

- Parent application managing child applications
- Separate applications for dev, staging, and production
- Environment-specific namespaces

## Usage Patterns

### Pattern 1: Direct Chart Deployment

Deploy a single chart directly from the Git repository:

```yaml
source:
  repoURL: 'https://github.com/isityael/helm-charts'
  path: charts/example-app
  targetRevision: main
```

### Pattern 2: Custom Values with Parameters

Override specific values using the `parameters` field:

```yaml
helm:
  parameters:
    - name: image.tag
      value: "v1.0.0"
    - name: replicaCount
      value: "3"
```

### Pattern 3: Custom Values with Inline YAML

Override values using inline YAML:

```yaml
helm:
  values: |
    replicaCount: 3
    image:
      tag: v1.0.0
```

### Pattern 4: Environment-Specific Values Files

Use different values files for different environments:

```yaml
# For development
helm:
  valueFiles:
    - values.yaml
    - values-dev.yaml

# For production
helm:
  valueFiles:
    - values.yaml
    - values-prod.yaml
```

## Monitoring Applications

### View application status

```bash
# List all applications
kubectl get applications -n argocd

# Get detailed information
kubectl describe application example-app -n argocd

# Or use ArgoCD CLI
argocd app list
argocd app get example-app
```

### View sync status

```bash
argocd app sync example-app
argocd app wait example-app
```

### View application logs

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## Sync Policies

### Automated Sync

Applications sync automatically when changes are detected:

```yaml
syncPolicy:
  automated:
    prune: true      # Remove resources not in Git
    selfHeal: true   # Sync when cluster state differs from Git
```

### Manual Sync

Require manual approval for syncs:

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
```

Then sync manually:

```bash
argocd app sync example-app
```

## Troubleshooting

### Application is OutOfSync

```bash
# View differences
argocd app diff example-app

# Force sync
argocd app sync example-app --force

# Refresh application
argocd app refresh example-app
```

### Application fails to sync

```bash
# Check sync status and errors
argocd app get example-app

# View detailed logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### View rendered manifests

```bash
# Get the manifests that ArgoCD would apply
argocd app manifests example-app
```

## Deleting Applications

```bash
# Delete the application (and optionally the deployed resources)
kubectl delete application example-app -n argocd

# Or using ArgoCD CLI
argocd app delete example-app

# Delete and cascade (remove all deployed resources)
argocd app delete example-app --cascade
```

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Integration](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
