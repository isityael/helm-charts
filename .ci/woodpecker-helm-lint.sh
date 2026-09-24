#!/usr/bin/env bash
set -euo pipefail

# Only the charts this run needs (all on push; touched charts on PRs).
# Command substitution (not <(...)) so a helper failure aborts under set -e.
selected_list="$(bash .ci/changed-charts.sh)"
mapfile -t selected <<<"${selected_list}"
[ -n "${selected_list}" ] || selected=()
if [ "${#selected[@]}" -eq 0 ]; then
  echo "No charts changed; nothing to lint."
  exit 0
fi
printf 'Charts in scope:\n'; printf '  %s\n' "${selected[@]}"

for chart in "${selected[@]}"; do
  chart="${chart}/"
  grep -E '^\s*repository:\s+https?://' "${chart}Chart.yaml" 2>/dev/null | awk '{print $2}' || true
done | sort -u | while read -r repo; do
  [ -n "${repo}" ] || continue
  name="repo-$(printf '%s' "${repo}" | md5sum | cut -c1-8)"
  helm repo add "${name}" "${repo}" 2>/dev/null || true
done

if grep -RqsE '^\s*repository:\s+oci://dhi\.io' charts/*/Chart.yaml; then
  if [ -n "${DHI_USERNAME:-}" ] && [ -n "${DHI_PASSWORD:-}" ]; then
    printf '%s\n' "${DHI_PASSWORD}" | helm registry login dhi.io -u "${DHI_USERNAME}" --password-stdin
  else
    echo "WARNING: DHI credentials not available;"
    echo "charts with oci://dhi.io dependencies may lint without subcharts."
  fi
fi

# Builds dependencies for the selected charts and fails on vendored drift.
bash .ci/check-helm-dependencies.sh "${selected[@]}"

# Dependencies were already built by check-helm-dependencies.sh above.
for chart in "${selected[@]}"; do
  chart="${chart}/"
  echo "==> Linting ${chart}"
  helm lint --with-subcharts "${chart}"
done

rm -rf .ci/rendered
mkdir -p .ci/rendered
for chart in "${selected[@]}"; do
  chart="${chart}/"
  name="$(basename "${chart}")"
  ci_values="$(find "${chart}ci" -maxdepth 1 -type f -name '*values*.yaml' 2>/dev/null | sort || true)"
  if [ -n "${ci_values}" ]; then
    printf '%s\n' "${ci_values}" | while read -r value_file; do
      suffix="$(printf '%s' "$(basename "${value_file}" .yaml)" | tr -c '[:alnum:]' '-' | sed 's/^-*//;s/-*$//')"
      echo "==> Rendering ${chart} with ${value_file}"
      helm template "ci-${name}-${suffix}" "${chart}" \
        --namespace "ci-${name}" \
        -f "${value_file}" > ".ci/rendered/${name}-${suffix}.yaml"
    done
  else
    echo "==> Rendering ${chart} with default values"
    helm template "ci-${name}" "${chart}" \
      --namespace "ci-${name}" \
      > ".ci/rendered/${name}.yaml"
  fi
done
