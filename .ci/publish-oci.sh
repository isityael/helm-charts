#!/usr/bin/env bash
set -euo pipefail

# Publish all charts to GHCR OCI, skipping versions that already exist.
# Expects GHCR_USERNAME and GHCR_TOKEN env vars.

helm registry login ghcr.io -u "$GHCR_USERNAME" -p "$GHCR_TOKEN"

for chart in charts/*/; do
  chartfile="${chart}Chart.yaml"
  [ -f "$chartfile" ] || continue

  name="$(basename "$chart")"
  version="$(grep '^version:' "$chartfile" | awk '{print $2}')"

  if helm show chart "oci://ghcr.io/sm-moshi/charts/${name}" --version "${version}" >/dev/null 2>&1; then
    echo "SKIP ${name}:${version} (already on GHCR)"
    continue
  fi

  echo "Linting ${name}..."
  helm lint "$chart"

  echo "Packaging and pushing ${name}:${version}..."
  pkg="$(helm package "$chart" -d /tmp/ | awk '{print $NF}')"
  helm push "$pkg" oci://ghcr.io/sm-moshi/charts
done
