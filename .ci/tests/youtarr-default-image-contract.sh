#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart_dir="${repo_root}/charts/youtarr"
rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT

helm template youtarr "${chart_dir}" >"${rendered}"

status=0
while IFS= read -r image; do
  separator_count="$(awk -F'@' '{ print NF - 1 }' <<<"${image}")"
  if ((separator_count > 1)); then
    echo "FAIL: rendered image contains more than one @ separator: ${image}" >&2
    status=1
  fi
done < <(yq -r '.. | select(type == "!!map" and has("image")) | .image' "${rendered}" | grep -v '^---$')

chart_app_version="$(yq -r '.appVersion' "${chart_dir}/Chart.yaml")"
configured_app_version="$(yq -r '.image.tag | split("@")[0]' "${chart_dir}/values.yaml")"
if [[ "${chart_app_version}" != "${configured_app_version}" ]]; then
  echo "FAIL: Chart appVersion ${chart_app_version} does not match configured Youtarr app version ${configured_app_version}" >&2
  status=1
fi

if ((status != 0)); then
  exit "${status}"
fi

echo "Youtarr default image contract passed"
