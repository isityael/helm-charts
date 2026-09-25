# Contributing

This repository publishes Helm charts as OCI artefacts to
`oci://ghcr.io/isityael/charts`.

## Prerequisites

- [mise](https://mise.jdx.dev/), which installs the pinned tools from `mise.toml`
  (Helm, kubeconform, kube-linter, prek and others)

## Local workflow

1. Install the hooks (once per clone):

   ```bash
   mise run hooks-install
   ```

   On commit, prek runs the YAML and JSON checks, bumps the owning chart's
   version, and lints the charts with staged changes via `.ci/helm-lint.sh`.

2. Lint and render charts, then validate the rendered manifests:

   ```bash
   mise run helm-lint              # all charts
   mise run helm-lint charts/<x>   # one chart
   mise run kube-linter
   ```

3. Run the repository contract tests:

   ```bash
   mise run test-shell
   ```

## Chart changes

- **Always bump the chart version** in `charts/<chart>/Chart.yaml` when you
  change templates or values. chart-version-guard enforces it in CI.
- Use SemVer: patch for fixes, minor for features, major for breaking changes.
- Commit `Chart.lock` and the vendored dependency archives under
  `charts/<chart>/charts/`. CI fails when they drift from `Chart.lock`.
- To exercise non-default paths, add CI values files under `charts/<chart>/ci/`
  (for example `test-values.yaml`). Every file matching `*values*.yaml` there
  is rendered and validated.

## CI

Woodpecker `build` runs on pull requests and on pushes to `main`. Pull requests
only lint and test the charts they touch, unless they change shared CI inputs.

- Renovate Helm authentication tests
- chart-version-guard
- Repository contract tests (`.ci/tests/`)
- Helm dependency drift, `helm lint --with-subcharts` and rendering
  (`.ci/helm-lint.sh`)
- kubeconform, with CRD schemas from the datreeio catalog
- kube-linter (`.kube-linter.yaml`)

## Release process

1. Merge to `main` with a bumped chart version.
2. Woodpecker `release-all` publishes every chart version that isn't on GHCR
   yet, plus the Artifact Hub metadata.
3. Forgejo Actions tags each published version as `<chart>-v<version>`.

## Artifact Hub

Repository metadata is in `artifacthub-repo.yml`; see the README for how OCI
charts are registered.
