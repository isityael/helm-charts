#!/usr/bin/env bash
set -euo pipefail

repo_root="${HELM_CHARTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "${repo_root}"

needs_update() {
  local chart="$1"
  local dependency_list
  local name
  local version
  local saw_dependency=false

  grep -qE '^[[:space:]]*dependencies:' "${chart}Chart.yaml" || return 1
  [ -f "${chart}Chart.lock" ] || return 0
  [ -d "${chart}charts" ] || return 0

  dependency_list="$(helm dependency list "${chart}")"
  while IFS=$'\t' read -r name version; do
    [ -n "${name}" ] || continue
    saw_dependency=true
    if [ -d "${chart}charts/${name}" ]; then
      continue
    fi
    if find "${chart}charts" -maxdepth 1 -type f -name "${name}-${version}*.tgz" -print -quit | grep -q .; then
      continue
    fi
    return 0
  done < <(
    printf '%s\n' "${dependency_list}" |
      awk '$1 == "NAME" { header = 1; next } header && NF >= 2 { print $1 "\t" $2 }'
  )

  [ "${saw_dependency}" = true ] || return 0
  return 1
}

built=0
skipped=0

for chart in charts/*/; do
  [ -f "${chart}Chart.yaml" ] || continue
  if ! needs_update "${chart}"; then
    skipped=$((skipped + 1))
    continue
  fi

  echo "  dep update: ${chart}"
  helm dependency update "${chart}"
  built=$((built + 1))
done

echo "  done: ${built} built, ${skipped} skipped (up-to-date)"
