#!/usr/bin/env bash
set -euo pipefail

# Publish all charts to GHCR OCI, skipping versions that already exist.
# Expects GHCR_USERNAME and GHCR_TOKEN env vars.

helm registry login ghcr.io -u "$GHCR_USERNAME" -p "$GHCR_TOKEN"

# Register dependency repos for charts using BJW-S common library
for chart in charts/*/; do
  [ -f "${chart}Chart.yaml" ] || continue
  grep -qE '^\s*repository:\s+https?://' "${chart}Chart.yaml" 2>/dev/null || continue
  grep -E '^\s*repository:\s+https?://' "${chart}Chart.yaml" | awk '{print $2}' | sort -u | while read -r repo; do
    rname="repo-$(echo "$repo" | md5sum | cut -c1-8)"
    helm repo add "$rname" "$repo" 2>/dev/null || true
  done
done

for chart in charts/*/; do
  chartfile="${chart}Chart.yaml"
  [ -f "$chartfile" ] || continue

  name="$(basename "$chart")"
  version="$(grep '^version:' "$chartfile" | awk '{print $2}')"

  if helm show chart "oci://ghcr.io/sm-moshi/charts/${name}" --version "${version}" >/dev/null 2>&1; then
    echo "SKIP ${name}:${version} (already on GHCR)"
    continue
  fi

  echo "Building deps for ${name}..."
  helm dependency build "$chart" 2>/dev/null || true

  echo "Linting ${name}..."
  helm lint "$chart"

  echo "Packaging and pushing ${name}:${version}..."
  pkg="$(helm package "$chart" -d /tmp/ | awk '{print $NF}')"
  helm push "$pkg" oci://ghcr.io/sm-moshi/charts
done
