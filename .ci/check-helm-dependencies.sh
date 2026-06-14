#!/usr/bin/env bash
set -euo pipefail

charts=()
for chart in charts/*/; do
  [ -f "${chart}Chart.yaml" ] || continue
  charts+=("${chart%/}")
done

failed=0

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

  status_before="$(git status --porcelain -- "${chart}/Chart.lock" "${chart}/charts")"
  if ! helm dependency build "${chart}"; then
    failed=1
    continue
  fi
  status_after="$(git status --porcelain -- "${chart}/Chart.lock" "${chart}/charts")"

  if [ "${status_before}" != "${status_after}" ]; then
    echo "Helm dependencies for ${chart} changed during dependency build:" >&2
    printf 'Before:\n%s\nAfter:\n%s\n' "${status_before:-<clean>}" "${status_after:-<clean>}" >&2
    failed=1
  fi
done

exit "${failed}"
