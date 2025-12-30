# Contributing

Thanks for contributing! This repository publishes Helm charts via GitHub Pages.

## Prerequisites

- Helm >= 3.12
- kubectl (only needed for install tests)
- Optional: `pre-commit` for local linting

## Local workflow (recommended)

1. Install hooks (per clone):

   ```bash
   git config core.hooksPath .githooks
   pre-commit install
   ```

2. Run linting locally:

   ```bash
   pre-commit run -a
   ct lint --config .ci/ct.yaml
   ```

3. Run install tests (requires kind):

   ```bash
   kind create cluster
   ct install --config .ci/ct.yaml
   ```

## Chart changes

- **Always bump the chart version** in `charts/<chart>/Chart.yaml` when you change templates or values.
- Use SemVer: patch for fixes, minor for features, major for breaking changes.
- If your chart uses dependencies, declare them in `Chart.yaml`.
  - Do **not** commit `charts/**/charts/` (vendored dependencies).
  - `Chart.lock` is optional but recommended when using version ranges.

## CI behavior

Pull requests run:

- `yamllint`
- `ct lint` (checks schema + version bumps)
- `ct install` on changed charts in a Kind cluster

To exercise non-default paths, add a CI values file at:

```text
charts/<chart>/ci/test-values.yaml
```

## Release process

- Merge to `main` with a bumped chart version.
- The `Release Charts` workflow packages charts and updates `index.yaml` on `gh-pages`.

## Artifact Hub

- Repository metadata is in `artifacthub-repo.yml` (root).
- Update `owners` and `repositoryID` after claiming the repo in Artifact Hub.
