#!/usr/bin/env bash
set -euo pipefail

# Publish charts to their configured Forgejo namespaces.
# Expects registry credentials for each configured destination; skips published versions.
: "${FORGEJO_PACKAGE_USERNAME:?FORGEJO_PACKAGE_USERNAME is required for chart publishing}"
: "${FORGEJO_PACKAGE_TOKEN:?FORGEJO_PACKAGE_TOKEN is required for chart publishing}"
printf '%s\n' "$FORGEJO_PACKAGE_TOKEN" \
  | helm registry login git.m0sh1.cc -u "$FORGEJO_PACKAGE_USERNAME" --password-stdin

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

for chart in charts/*/; do
  chartfile="${chart}Chart.yaml"
  [ -f "$chartfile" ] || continue

  name="$(basename "$chart")"
  version="$(grep '^version:' "$chartfile" | awk '{print $2}')"
  case "$name" in
    kded-catalog) repository="git.m0sh1.cc/m0sh1-internal/charts" ;;
    *) repository="git.m0sh1.cc/isityael/charts" ;;
  esac

  if helm show chart "oci://${repository}/${name}" --version "${version}" >/dev/null 2>&1; then
    echo "SKIP ${name}:${version} (already on ${repository})"
    continue
  fi

  # Publish the same committed dependencies that passed build validation.
  # Rebuilding here could silently fetch a republished upstream chart version.
  dependencies="$(helm dependency list "$chart")"
  if printf '%s\n' "$dependencies" | awk 'NR > 1 && $NF != "ok" && !($NF == "unpacked" && NF == 3) { bad = 1 } END { exit bad ? 0 : 1 }'; then
    printf '%s\n' "$dependencies" >&2
    exit 1
  fi

  echo "Linting ${name}..."
  helm lint --with-subcharts "$chart"

  echo "Packaging and pushing ${name}:${version}..."
  pkg="$(helm package "$chart" -d /tmp/ | awk '{print $NF}')"
  push_output="$(helm push "$pkg" "oci://${repository}" 2>&1)"
  printf '%s\n' "$push_output"

  digest="$(printf '%s\n' "$push_output" | awk '/^Digest:/ {print $2; exit}')"
  if [ -z "$digest" ]; then
    echo "Unable to find pushed digest for ${name}:${version}." >&2
    exit 1
  fi

  ref="${repository}/${name}@${digest}"
  printf '%s\n' "$ref" >>"$published_refs_file"
  sign_ref "$ref"

done
