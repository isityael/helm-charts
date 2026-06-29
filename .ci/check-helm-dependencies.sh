#!/usr/bin/env bash
set -euo pipefail

charts=()
for chart in charts/*/; do
  [ -f "${chart}Chart.yaml" ] || continue
  chart="${chart%/}"
  if [ "${chart}" = "charts/cnpg-stack" ] &&
    { [ -z "${DHI_USERNAME:-}" ] || [ -z "${DHI_PASSWORD:-}" ]; }; then
    echo "Skipping dependency check for ${chart}; DHI credentials are not available."
    continue
  fi
  charts+=("${chart}")
done

failed=0

if [ "${#charts[@]}" -eq 0 ]; then
  exit 0
fi

dependency_snapshot() {
  local chart="$1"

  {
    [ -f "${chart}/Chart.lock" ] && printf '%s\n' "${chart}/Chart.lock"
    [ -d "${chart}/charts" ] && find "${chart}/charts" -type f
  } | sort | while IFS= read -r file; do
    case "${file}" in
      *.tgz)
        printf '%s %s\n' "$(helm show all "${file}" | cksum)" "${file}"
        ;;
      *)
        cksum "$file"
        ;;
    esac
  done
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
