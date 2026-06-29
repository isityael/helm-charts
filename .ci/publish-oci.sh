#!/usr/bin/env bash
set -euo pipefail

# Publish all charts to GHCR OCI, skipping versions that already exist.
# Expects GHCR_USERNAME and GHCR_TOKEN env vars.
printf '%s\n' "$GHCR_TOKEN" | helm registry login ghcr.io -u "$GHCR_USERNAME" --password-stdin

published_refs_file=".ci/published-oci-refs.txt"
mkdir -p "$(dirname "$published_refs_file")"
: >"$published_refs_file"

sign_ref() {
  local ref="$1"

  if [ -z "${COSIGN_PRIVATE_KEY:-}" ]; then
    return 0
  fi
  if [ -z "${COSIGN_PASSWORD:-}" ]; then
    echo "COSIGN_PASSWORD is required when COSIGN_PRIVATE_KEY is set." >&2
    exit 1
  fi
  if ! command -v cosign >/dev/null 2>&1; then
    echo "cosign is required when COSIGN_PRIVATE_KEY is set." >&2
    exit 1
  fi

  echo "Signing ${ref}..."
  cosign sign --yes --key env://COSIGN_PRIVATE_KEY "$ref"
}

if grep -RqsE '^\s*repository:\s+oci://dhi\.io' charts/*/Chart.yaml; then
  if [ -z "${DHI_USERNAME:-}" ] || [ -z "${DHI_PASSWORD:-}" ]; then
    echo "DHI credentials are required for charts that depend on oci://dhi.io."
    echo "Set DHI_USERNAME and DHI_PASSWORD in CI secrets."
    exit 1
  fi
  printf '%s\n' "$DHI_PASSWORD" | helm registry login dhi.io -u "$DHI_USERNAME" --password-stdin
fi

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

  if helm show chart "oci://ghcr.io/yaelmoshi/charts/${name}" --version "${version}" >/dev/null 2>&1; then
    echo "SKIP ${name}:${version} (already on GHCR)"
    continue
  fi

  echo "Building deps for ${name}..."
  helm dependency build "$chart"

  echo "Linting ${name}..."
  case "$name" in
    matrix-umbrella)
      # This umbrella chart is validated with parent values because some
      # upstream dependencies do not lint standalone with their defaults.
      helm lint "$chart"
      ;;
    *)
      helm lint --with-subcharts "$chart"
      ;;
  esac

  echo "Packaging and pushing ${name}:${version}..."
  pkg="$(helm package "$chart" -d /tmp/ | awk '{print $NF}')"
  push_output="$(helm push "$pkg" oci://ghcr.io/yaelmoshi/charts 2>&1)"
  printf '%s\n' "$push_output"

  digest="$(printf '%s\n' "$push_output" | awk '/^Digest:/ {print $2; exit}')"
  if [ -z "$digest" ]; then
    echo "Unable to find pushed digest for ${name}:${version}." >&2
    exit 1
  fi

  ref="ghcr.io/yaelmoshi/charts/${name}@${digest}"
  printf '%s\n' "$ref" >>"$published_refs_file"
  sign_ref "$ref"
done
