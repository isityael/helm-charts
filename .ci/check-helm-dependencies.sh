#!/usr/bin/env bash
set -euo pipefail

charts=()
for chart in charts/*/; do
  [ -f "${chart}Chart.yaml" ] || continue
  charts+=("${chart%/}")
done

failed=0

dependency_snapshot() {
  local chart="$1"

  {
    [ -f "${chart}/Chart.lock" ] && printf '%s\n' "${chart}/Chart.lock"
    [ -d "${chart}/charts" ] && find "${chart}/charts" -type f
  } | sort | while IFS= read -r file; do
    cksum "$file"
  done
}

needs_dhi_auth() {
  local chart="$1"

  grep -qE '^[[:space:]]*repository:[[:space:]]+oci://dhi\.io' "${chart}/Chart.yaml"
}

has_dhi_auth() {
  [ -n "${DHI_USERNAME:-}" ] && [ -n "${DHI_PASSWORD:-}" ]
}

for chart in "${charts[@]}"; do
  if ! grep -qE '^[[:space:]]*dependencies:' "${chart}/Chart.yaml"; then
    continue
  fi

  echo "==> Checking Helm dependencies for ${chart}"

  list_before="$(helm dependency list "${chart}")"
  if printf '%s\n' "${list_before}" | awk 'NR > 1 && $NF != "ok" { bad = 1 } END { exit bad ? 0 : 1 }'; then
    printf '%s\n' "${list_before}" >&2
    failed=1
  fi

  status_before="$(dependency_snapshot "${chart}")"
  if needs_dhi_auth "${chart}" && ! has_dhi_auth; then
    echo "Skipping dependency build for ${chart}; DHI credentials are not available."
    continue
  fi

  if ! helm dependency build "${chart}"; then
    failed=1
    continue
  fi
  status_after="$(dependency_snapshot "${chart}")"

  if [ "${status_before}" != "${status_after}" ]; then
    echo "Helm dependencies for ${chart} changed during dependency build:" >&2
    printf 'Before:\n%s\nAfter:\n%s\n' "${status_before:-<empty>}" "${status_after:-<empty>}" >&2
    failed=1
  fi
done

exit "${failed}"
