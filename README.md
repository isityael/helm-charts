# Helm Charts Repository

This repository hosts Helm charts for deployment in Kubernetes clusters using ArgoCD and other GitOps tools.

## Repository Structure

```
.
├── charts/                  # Helm charts directory
│   └── <chart-name>/       # Individual chart directories
│       ├── Chart.yaml      # Chart metadata
│       ├── values.yaml     # Default values
│       └── templates/      # Kubernetes manifest templates
├── .github/                # GitHub workflows (optional)
│   └── workflows/          # CI/CD pipelines
└── README.md               # This file
```

## Getting Started

### Prerequisites

- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Access to a Kubernetes cluster
- (Optional) [ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/) installed in your cluster

### Creating a New Chart

1. Create a new chart in the `charts/` directory:
   ```bash
   cd charts/
   helm create <chart-name>
   ```

2. Customize the chart according to your application needs:
   - Edit `Chart.yaml` for chart metadata
   - Configure `values.yaml` for default values
   - Modify templates in the `templates/` directory

3. Validate your chart:
   ```bash
   helm lint charts/<chart-name>
   ```

4. Package the chart (optional):
   ```bash
   helm package charts/<chart-name>
   ```

### Using Charts

#### Method 1: Direct Deployment with Helm

```bash
# Install from local directory
helm install <release-name> ./charts/<chart-name>

# Install with custom values
helm install <release-name> ./charts/<chart-name> -f custom-values.yaml

# Upgrade existing release
helm upgrade <release-name> ./charts/<chart-name>
```

#### Method 2: Deployment with ArgoCD

Create an ArgoCD Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<username>/helm-charts'
    path: charts/<chart-name>
    targetRevision: main
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: <target-namespace>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Apply the Application:
```bash
kubectl apply -f argocd-application.yaml
```

#### Method 3: Using as a Helm Repository (GitHub Pages)

If this repository is configured with GitHub Pages, you can add it as a Helm repository:

```bash
# Add the repository
helm repo add <repo-name> https://<username>.github.io/helm-charts

# Update repository cache
helm repo update

# Install a chart
helm install <release-name> <repo-name>/<chart-name>
```

## Chart Development Best Practices

1. **Semantic Versioning**: Follow [SemVer](https://semver.org/) for chart versions
2. **Documentation**: Include a comprehensive `README.md` in each chart
3. **Values Documentation**: Comment all values in `values.yaml`
4. **Validation**: Always run `helm lint` before committing
5. **Testing**: Test your charts with `helm install --dry-run --debug`
6. **Dependencies**: Document all chart dependencies in `Chart.yaml`

## Testing Charts Locally

```bash
# Lint the chart
helm lint charts/<chart-name>

# Dry-run installation
helm install test-release charts/<chart-name> --dry-run --debug

# Template rendering
helm template test-release charts/<chart-name>

# Install to a test namespace
helm install test-release charts/<chart-name> -n test --create-namespace
```

## ArgoCD Integration Patterns

### Pattern 1: Single Application
Point ArgoCD directly to a chart path in this repository.

### Pattern 2: App of Apps
Use ArgoCD's "App of Apps" pattern to manage multiple charts:
- Create a parent application that references child applications
- Each child application points to a chart in this repository

### Pattern 3: Environment-Specific Values
Store environment-specific values files alongside charts or in separate directories:
```yaml
helm:
  valueFiles:
    - values.yaml
    - values-prod.yaml
```

## Contributing

1. Create a new branch for your chart or changes
2. Follow the chart development best practices
3. Validate your charts with `helm lint`
4. Test your charts in a development cluster
5. Submit a pull request with a clear description

## Useful Commands

```bash
# Create a new chart
helm create charts/<chart-name>

# Lint a chart
helm lint charts/<chart-name>

# Package a chart
helm package charts/<chart-name>

# Generate index.yaml for Helm repository
helm repo index . --url https://<username>.github.io/helm-charts

# Show chart values
helm show values charts/<chart-name>

# Show chart information
helm show chart charts/<chart-name>

# Show all chart information
helm show all charts/<chart-name>
```

## Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Integration](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## License

See [LICENSE](LICENSE) file for details.