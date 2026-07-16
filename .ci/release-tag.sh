#!/usr/bin/env bash
set -euo pipefail

tag="${CI_COMMIT_TAG:-}"

if [[ ! "$tag" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?)-v([0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)*)$ ]]; then
  echo "invalid release tag: expected <chart>-v<Chart.yaml version>" >&2
  exit 1
fi

chart="${BASH_REMATCH[1]}"
tag_version="${BASH_REMATCH[3]}"
chart_file="charts/${chart}/Chart.yaml"

if [ ! -f "$chart_file" ]; then
  echo "unknown chart in release tag: ${chart}" >&2
  exit 1
fi

chart_name="$(awk '$1 == "name:" { value = $2; gsub(/["'\'' ]/, "", value); print value; exit }' "$chart_file")"
chart_version="$(awk '$1 == "version:" { value = $2; gsub(/["'\'' ]/, "", value); print value; exit }' "$chart_file")"

if [ "$chart_name" != "$chart" ]; then
  echo "release tag chart ${chart} does not match Chart.yaml name ${chart_name:-<missing>}" >&2
  exit 1
fi

if [ "$tag_version" != "$chart_version" ]; then
  echo "release tag version ${tag_version} does not match ${chart_file} version ${chart_version:-<missing>}" >&2
  exit 1
fi

: "${GHCR_USERNAME:?GHCR_USERNAME is required}"
: "${GHCR_TOKEN:?GHCR_TOKEN is required}"

oci_ref="oci://ghcr.io/isityael/charts/${chart}"
artifact_dir="release-artifacts"
artifact="${artifact_dir}/${chart}-${chart_version}.tgz"

printf '%s\n' "$GHCR_TOKEN" \
  | helm registry login ghcr.io -u "$GHCR_USERNAME" --password-stdin

if ! helm show chart "$oci_ref" --version "$chart_version" >/dev/null; then
  echo "OCI chart does not exist: ${oci_ref}:${chart_version}" >&2
  exit 1
fi

mkdir -p "$artifact_dir"
rm -f "$artifact"
helm pull "$oci_ref" --version "$chart_version" --destination "$artifact_dir"

if [ ! -f "$artifact" ]; then
  echo "Helm did not produce the expected release artifact: ${artifact}" >&2
  exit 1
fi

echo "Pulled existing OCI chart for GitHub release: ${artifact}"
