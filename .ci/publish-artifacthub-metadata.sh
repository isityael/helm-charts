#!/usr/bin/env bash
set -euo pipefail

registry="${OCI_REGISTRY:-ghcr.io}"
namespace="${OCI_NAMESPACE:-isityael/charts}"
metadata_file="${ARTIFACTHUB_METADATA_FILE:-artifacthub-repo.yml}"
oras_bin="${ORAS_BIN:-oras}"

if [ ! -s "$metadata_file" ]; then
  echo "Artifact Hub repository metadata file is missing or empty: ${metadata_file}" >&2
  exit 1
fi
if [ -z "${GHCR_USERNAME:-}" ] || [ -z "${GHCR_TOKEN:-}" ]; then
  echo "GHCR_USERNAME and GHCR_TOKEN are required to publish Artifact Hub metadata." >&2
  exit 1
fi
if ! command -v "$oras_bin" >/dev/null 2>&1; then
  echo "oras is required to publish Artifact Hub OCI repository metadata." >&2
  exit 1
fi

oci_metadata_file="$(mktemp "./.artifacthub-repo-oci.XXXXXX")"
trap 'rm -f "$oci_metadata_file"' EXIT
awk '
  /^owners:[[:space:]]*$/ {
    capture = 1
  }
  capture && /^[^[:space:]#][^:]*:[[:space:]]*/ && !/^owners:[[:space:]]*$/ {
    exit
  }
  capture {
    print
  }
' "$metadata_file" >"$oci_metadata_file"
if ! grep -q '^owners:[[:space:]]*$' "$oci_metadata_file" \
  || ! grep -q '^[[:space:]]*- name:[[:space:]]*[^[:space:]]' "$oci_metadata_file"; then
  echo "Artifact Hub repository metadata must contain at least one owner." >&2
  exit 1
fi

printf '%s\n' "$GHCR_TOKEN" \
  | "$oras_bin" login "$registry" --username "$GHCR_USERNAME" --password-stdin

found_chart=0
for chart_file in charts/*/Chart.yaml; do
  [ -f "$chart_file" ] || continue
  found_chart=1
  chart_name="$(awk '/^name:[[:space:]]*/ { print $2; exit }' "$chart_file")"
  if [ -z "$chart_name" ]; then
    echo "Unable to determine chart name from ${chart_file}." >&2
    exit 1
  fi

  ref="${registry}/${namespace}/${chart_name}:artifacthub.io"
  echo "Publishing Artifact Hub repository metadata to ${ref}..."
  "$oras_bin" push "$ref" \
    --config /dev/null:application/vnd.cncf.artifacthub.config.v1+yaml \
    "${oci_metadata_file}:application/vnd.cncf.artifacthub.repository-metadata.layer.v1.yaml"
done

if [ "$found_chart" -eq 0 ]; then
  echo "No Helm charts found under charts/." >&2
  exit 1
fi
