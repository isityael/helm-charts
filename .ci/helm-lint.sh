#!/usr/bin/env bash
# Lint and render Helm charts. Used by Woodpecker and the prek hook.
#
#   .ci/helm-lint.sh             charts from .ci/changed-charts.sh (CI)
#   .ci/helm-lint.sh --staged    charts with staged changes (prek hook)
#   .ci/helm-lint.sh charts/x    the given charts
#
# Dependencies are built in a copy of charts/ so the checkout's vendored
# archives are never rewritten; .ci/check-helm-dependencies.sh fails on drift.
# Rendered manifests land in .ci/rendered for kubeconform and kube-linter.
set -euo pipefail

command -v helm >/dev/null 2>&1 || {
  echo "helm is not installed or not on PATH." >&2
  exit 1
}

repo_root="$(pwd)"

if [ "${1:-}" = "--staged" ]; then
  selected_list="$(git diff --cached --name-only --diff-filter=ACM |
    awk -F/ '$1 == "charts" && NF >= 3 { print $1 "/" $2 }' | sort -u)"
elif [ "$#" -gt 0 ]; then
  selected_list="$(printf '%s\n' "${@%/}")"
else
  # Command substitution (not <(...)) so a helper failure aborts under set -e.
  selected_list="$(bash .ci/changed-charts.sh)"
fi

selected=()
while IFS= read -r chart; do
  [ -n "${chart}" ] && [ -f "${chart}/Chart.yaml" ] && selected+=("${chart}")
done <<<"${selected_list}"
if [ "${#selected[@]}" -eq 0 ]; then
  echo "No charts changed; nothing to lint."
  exit 0
fi
printf 'Charts in scope:\n'; printf '  %s\n' "${selected[@]}"

helm_repo_url_exists() {
  helm repo list 2>/dev/null | awk 'NR>1 {print $2}' | grep -qx "$1"
}

helm_repo_name_exists() {
  helm repo list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$1"
}

i=0
for chart in "${selected[@]}"; do
  grep -E '^[[:space:]]*repository:[[:space:]]+https?://' "${chart}/Chart.yaml" | awk '{print $2}' || true
done | sort -u | while IFS= read -r repo; do
  [ -n "${repo}" ] || continue
  helm_repo_url_exists "${repo}" && continue
  while helm_repo_name_exists "repo-${i}"; do i=$((i + 1)); done
  echo "helm repo add repo-${i} ${repo}"
  helm repo add "repo-${i}" "${repo}"
done

if grep -qsE '^[[:space:]]*repository:[[:space:]]+oci://dhi\.io' "${selected[@]/%//Chart.yaml}"; then
  if [ -n "${DHI_USERNAME:-}" ] && [ -n "${DHI_PASSWORD:-}" ]; then
    printf '%s\n' "${DHI_PASSWORD}" | helm registry login dhi.io -u "${DHI_USERNAME}" --password-stdin
  else
    echo "WARNING: DHI credentials not available;"
    echo "charts with oci://dhi.io dependencies lint against their vendored archives."
  fi
fi

# Helm repackages file:// dependencies with fresh archive metadata, so work
# on a complete sibling chart tree instead of the checkout.
validation_root="$(mktemp -d)"
trap 'rm -rf "${validation_root}"' EXIT
cp -R charts "${validation_root}/charts"
cd "${validation_root}"

# Builds dependencies for the selected charts and fails on vendored drift.
bash "${repo_root}/.ci/check-helm-dependencies.sh" "${selected[@]}"

for chart in "${selected[@]}"; do
  echo "==> Linting ${chart}"
  helm lint --with-subcharts "${chart}"
done

rendered="${repo_root}/.ci/rendered"
rm -rf "${rendered}"
mkdir -p "${rendered}"
for chart in "${selected[@]}"; do
  name="$(basename "${chart}")"
  ci_values="$(find "${chart}/ci" -maxdepth 1 -type f -name '*values*.yaml' 2>/dev/null | sort || true)"
  if [ -n "${ci_values}" ]; then
    while IFS= read -r value_file; do
      suffix="$(printf '%s' "$(basename "${value_file}" .yaml)" | tr -c '[:alnum:]' '-' | sed 's/^-*//;s/-*$//')"
      echo "==> Rendering ${chart} with ${value_file}"
      helm template "ci-${name}-${suffix}" "${chart}" \
        --namespace "ci-${name}" \
        -f "${value_file}" >"${rendered}/${name}-${suffix}.yaml"
    done <<<"${ci_values}"
  else
    echo "==> Rendering ${chart} with default values"
    helm template "ci-${name}" "${chart}" \
      --namespace "ci-${name}" \
      >"${rendered}/${name}.yaml"
  fi
done
