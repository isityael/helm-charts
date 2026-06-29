#!/usr/bin/env bash
set -euo pipefail

for chart in charts/*/; do
  [ -f "${chart}Chart.yaml" ] || continue
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

if [ -n "${DHI_USERNAME:-}" ] && [ -n "${DHI_PASSWORD:-}" ]; then
  bash .ci/check-helm-dependencies.sh
else
  echo "Skipping Helm dependency guard; DHI credentials are not available."
fi

chart_uses_dhi_dependency() {
  grep -qsE '^\s*repository:\s+oci://dhi\.io' "$1/Chart.yaml"
}

for chart in charts/*/; do
  echo "==> Linting ${chart}"
  if chart_uses_dhi_dependency "${chart}" &&
    { [ -z "${DHI_USERNAME:-}" ] || [ -z "${DHI_PASSWORD:-}" ]; }; then
    echo "Skipping dependency build for ${chart}; DHI credentials are not available."
  else
    helm dependency build "${chart}"
  fi
  case "${chart}" in
    charts/matrix-umbrella/)
      # The umbrella chart renders with parent values, but two upstream
      # dependencies do not lint as standalone charts with their own defaults.
      # Keep dependency drift checks + rendered manifest validation below.
      helm lint "${chart}"
      ;;
    *)
      helm lint --with-subcharts "${chart}"
      ;;
  esac
done

rm -rf .ci/rendered
mkdir -p .ci/rendered
for chart in charts/*/; do
  [ -f "${chart}Chart.yaml" ] || continue
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
