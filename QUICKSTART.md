# Quick Start Guide

This guide will help you get started with using the Helm charts in this repository with ArgoCD.

## Prerequisites

- Kubernetes cluster with kubectl access
- ArgoCD installed in your cluster
- Basic knowledge of Kubernetes and Helm

## 5-Minute Quick Start

### Step 1: Deploy the Example App with ArgoCD

```bash
# Apply the example ArgoCD application
kubectl apply -f examples/argocd/example-app.yaml

# Watch the application sync
kubectl get application -n argocd -w
```

### Step 2: Verify the Deployment

```bash
# Check the application status
kubectl get application example-app -n argocd

# View the deployed resources
kubectl get all -n default -l app.kubernetes.io/name=example-app

# Check pod status
kubectl get pods -n default -l app.kubernetes.io/name=example-app
```

### Step 3: Access the Application

```bash
# Port-forward to access the service
kubectl port-forward -n default svc/example-app 8080:80

# Open http://localhost:8080 in your browser
```

## Using Your Own Chart

### Quick Method: Clone and Customize

```bash
# Clone this repository
git clone https://github.com/isityael/helm-charts.git
cd helm-charts

# Copy the example chart
cp -r charts/example-app charts/my-app

# Edit your chart
vim charts/my-app/Chart.yaml
vim charts/my-app/values.yaml
vim charts/my-app/templates/deployment.yaml

# Validate your chart
helm lint charts/my-app

# Commit and push
git add charts/my-app
git commit -m "Add my-app chart"
git push
```

### Deploy Your Chart with ArgoCD

```bash
# Copy the example ArgoCD application
cp examples/argocd/example-app.yaml my-app-argocd.yaml

# Edit the manifest
# - Change metadata.name to "my-app"
# - Change spec.source.path to "charts/my-app"
# - Update other settings as needed

# Apply the ArgoCD application
kubectl apply -f my-app-argocd.yaml
```

## Common Commands

### Helm Commands

```bash
# Create a new chart
helm create charts/new-chart

# Lint a chart
helm lint charts/my-chart

# Test template rendering
helm template my-release charts/my-chart

# Install locally (without ArgoCD)
helm install my-release charts/my-chart

# Upgrade a release
helm upgrade my-release charts/my-chart
```

### ArgoCD Commands

```bash
# View all applications
argocd app list

# Get application details
argocd app get my-app

# Sync an application
argocd app sync my-app

# View sync status
argocd app wait my-app

# Delete an application
argocd app delete my-app
```

### Kubectl Commands

```bash
# View ArgoCD applications
kubectl get applications -n argocd

# Get application details
kubectl describe application my-app -n argocd

# View application logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# View deployed resources
kubectl get all -n <namespace>
```

## Next Steps

1. **Read the Documentation**
   - [Main README](README.md) - Repository overview
   - [Contributing Guide](CONTRIBUTING.md) - Development guidelines
   - [ArgoCD Examples](examples/argocd/README.md) - Detailed ArgoCD patterns

2. **Explore the Example Chart**
   - Review [charts/example-app/README.md](charts/example-app/README.md)
   - Study the templates in `charts/example-app/templates/`
   - Understand the values in `charts/example-app/values.yaml`

3. **Try Different Patterns**
   - Deploy with custom values: `examples/argocd/example-app-custom-values.yaml`
   - Deploy to multiple environments: `examples/argocd/example-app-multi-env.yaml`

4. **Create Your Own Charts**
   - Start with the example chart as a template
   - Follow the guidelines in [CONTRIBUTING.md](CONTRIBUTING.md)
   - Test thoroughly before deploying to production

## Troubleshooting

### Application Not Syncing

```bash
# Check application status
kubectl describe application my-app -n argocd

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller

# Manually sync
argocd app sync my-app --force
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n <namespace>

# View pod logs
kubectl logs -n <namespace> <pod-name>

# Describe pod for events
kubectl describe pod -n <namespace> <pod-name>
```

### Chart Validation Errors

```bash
# Lint the chart
helm lint charts/my-chart

# Test template rendering
helm template test charts/my-chart --debug

# Dry-run installation
helm install test charts/my-chart --dry-run --debug
```

## Getting Help

- Open an issue on GitHub for bugs or questions
- Check the [ArgoCD documentation](https://argo-cd.readthedocs.io/)
- Review [Helm documentation](https://helm.sh/docs/)

## Resources

- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [ArgoCD User Guide](https://argo-cd.readthedocs.io/en/stable/user-guide/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
