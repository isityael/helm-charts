# Contributing to Helm Charts Repository

Thank you for your interest in contributing to this Helm charts repository! This guide will help you get started.

## Table of Contents

- [Getting Started](#getting-started)
- [Chart Development Guidelines](#chart-development-guidelines)
- [Testing Your Changes](#testing-your-changes)
- [Submitting Changes](#submitting-changes)
- [Code Review Process](#code-review-process)

## Getting Started

### Prerequisites

Before contributing, ensure you have the following installed:

- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Git](https://git-scm.com/)
- Access to a Kubernetes cluster (for testing)
  - [Minikube](https://minikube.sigs.k8s.io/docs/start/) (local development)
  - [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker)
  - [k3d](https://k3d.io/) (Lightweight Kubernetes)

### Development Setup

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/helm-charts.git
   cd helm-charts
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/isityael/helm-charts.git
   ```
4. Create a new branch for your changes:
   ```bash
   git checkout -b feature/my-new-chart
   ```

## Chart Development Guidelines

### Creating a New Chart

1. Create your chart in the `charts/` directory:
   ```bash
   cd charts/
   helm create my-new-chart
   ```

2. Update `Chart.yaml` with accurate information:
   ```yaml
   apiVersion: v2
   name: my-new-chart
   description: A clear description of what this chart does
   type: application
   version: 0.1.0
   appVersion: "1.0.0"
   keywords:
     - relevant
     - keywords
   maintainers:
     - name: Your Name
       email: your.email@example.com
   ```

3. Document all values in `values.yaml` with comments:
   ```yaml
   # Number of replicas to deploy
   replicaCount: 1
   
   image:
     # Container image repository
     repository: nginx
     # Image pull policy
     pullPolicy: IfNotPresent
     # Override the image tag (defaults to chart appVersion)
     tag: ""
   ```

4. Create a comprehensive `README.md` for your chart

### Chart Best Practices

Follow these best practices when developing charts:

#### 1. Semantic Versioning

- Use [Semantic Versioning](https://semver.org/) for chart versions
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes (backward compatible)

#### 2. Resource Naming

- Use templates for resource names: `{{ include "chart.fullname" . }}`
- Follow Kubernetes naming conventions
- Keep names within 63 characters

#### 3. Labels and Annotations

Include standard labels on all resources:
```yaml
labels:
  helm.sh/chart: {{ include "chart.chart" . }}
  app.kubernetes.io/name: {{ include "chart.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
```

#### 4. Values Structure

- Group related values together
- Use meaningful names
- Provide sensible defaults
- Document all values with comments

#### 5. Templates

- Use helper templates (in `_helpers.tpl`) for reusable content
- Keep templates simple and readable
- Use proper indentation
- Add comments for complex logic

#### 6. Security

- Never include secrets in the chart or default values
- Use `secretKeyRef` for sensitive data
- Set appropriate RBAC permissions
- Follow the principle of least privilege
- Set security contexts appropriately

#### 7. Documentation

Every chart must include:
- Comprehensive `README.md`
- Description in `Chart.yaml`
- Comments in `values.yaml`
- Usage examples
- Configuration options table

## Testing Your Changes

### 1. Lint Your Chart

```bash
helm lint charts/my-new-chart
```

### 2. Template Rendering

```bash
# Test template rendering
helm template test-release charts/my-new-chart

# Test with custom values
helm template test-release charts/my-new-chart -f custom-values.yaml
```

### 3. Dry Run

```bash
# Dry run (requires kubectl connection)
helm install test-release charts/my-new-chart --dry-run --debug
```

### 4. Install in Test Cluster

```bash
# Create a test namespace
kubectl create namespace test

# Install the chart
helm install test-release charts/my-new-chart -n test

# Check the deployment
kubectl get all -n test

# Test the application
kubectl port-forward -n test svc/test-release-my-new-chart 8080:80

# Uninstall when done
helm uninstall test-release -n test
kubectl delete namespace test
```

### 5. Test with Different Values

```bash
# Test with minimal configuration
helm template test charts/my-new-chart --set replicaCount=1

# Test with maximum configuration
helm template test charts/my-new-chart --set ingress.enabled=true --set autoscaling.enabled=true
```

### 6. Test Upgrades

```bash
# Install version 1
helm install test charts/my-new-chart -n test

# Make changes and upgrade
helm upgrade test charts/my-new-chart -n test

# Verify upgrade worked
helm history test -n test
```

## Submitting Changes

### 1. Commit Your Changes

```bash
# Stage your changes
git add charts/my-new-chart/

# Commit with a descriptive message
git commit -m "Add new chart for my-application"
```

### Commit Message Guidelines

- Use clear, descriptive commit messages
- Start with a verb in imperative mood (Add, Update, Fix, etc.)
- Keep the first line under 50 characters
- Add detailed description if needed

Examples:
```
Add Redis chart for caching layer
Update nginx chart to version 1.2.0
Fix service port configuration in app chart
```

### 2. Push to Your Fork

```bash
git push origin feature/my-new-chart
```

### 3. Create a Pull Request

1. Go to the original repository on GitHub
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill in the PR template with:
   - Description of changes
   - Related issues
   - Testing performed
   - Breaking changes (if any)

### Pull Request Guidelines

- One chart per PR (unless changes are tightly related)
- Include tests and documentation
- Ensure all CI checks pass
- Respond to review feedback promptly

## Code Review Process

### What to Expect

1. **Automated Checks**: CI will run linting and tests
2. **Maintainer Review**: A maintainer will review your changes
3. **Feedback**: You may receive requests for changes
4. **Approval**: Once approved, your PR will be merged

### Review Criteria

Reviewers will check:
- Chart follows best practices
- Documentation is comprehensive
- Tests are included
- Values are well-documented
- Templates are correct and efficient
- No security issues

## Updating Existing Charts

When updating an existing chart:

1. Update the version in `Chart.yaml`:
   - Patch version for bug fixes
   - Minor version for new features
   - Major version for breaking changes

2. Update the `CHANGELOG.md` (if present) or include changes in PR description

3. Test the upgrade path:
   ```bash
   # Install old version
   helm install test charts/my-chart
   
   # Upgrade to new version
   helm upgrade test charts/my-chart
   
   # Verify nothing broke
   helm test test
   ```

4. Document any breaking changes clearly

## Getting Help

- Open an issue for questions or problems
- Tag maintainers in your PR for attention
- Check existing issues and PRs for similar work

## Additional Resources

- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

## License

By contributing to this repository, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing! 🎉
