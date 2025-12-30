# Helm Charts

This repository hosts Helm charts published via GitHub Pages.

## Usage

```bash
helm repo add isityael https://isityael.github.io/helm-charts
helm repo update

# Install a chart
helm install <release-name> isityael/<chart-name>
```

## Charts

- `homepage`
- `example-app`

## Publish a Chart

1. Bump the version in `charts/<chart-name>/Chart.yaml`.
2. Push/merge to `main`.
3. The `Release Charts` workflow packages charts and updates `index.yaml` on `gh-pages`.

## Contributing

- Run `helm lint charts/<chart-name>` before opening a PR.
- Include a short summary of changes in the PR description.

## License

See `LICENSE`.
