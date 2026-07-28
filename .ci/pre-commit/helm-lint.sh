#!/usr/bin/env bash
set -euo pipefail

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is not installed or not on PATH."
  exit 1
fi

changed_files=$(git diff --cached --name-only --diff-filter=ACM | grep '^charts/' || true)
if [ -z "$changed_files" ]; then
  exit 0
fi

charts=$(echo "$changed_files" | awk -F/ 'NF>=2 {print $1"/"$2}' | sort -u)

helm_repo_url_exists() {
  local repo="$1"
  helm repo list 2>/dev/null | awk 'NR>1 {print $2}' | grep -qx "$repo"
}

helm_repo_name_exists() {
  local name="$1"
  helm repo list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$name"
}

next_repo_name() {
  while helm_repo_name_exists "repo-${i}"; do
    i=$((i + 1))
  done
  printf 'repo-%s\n' "$i"
}

repos=$(for chart in $charts; do
  chart_file="$chart/Chart.yaml"
  [ -f "$chart_file" ] || continue
  grep -E '^[[:space:]]*repository:[[:space:]]+https?://' "$chart_file" 2>/dev/null | awk '{print $2}' || true
done | sort -u)

chart_uses_dhi_dependency() {
  grep -qE '^[[:space:]]*repository:[[:space:]]+oci://dhi\.io' "$1/Chart.yaml"
}

if [ -n "$repos" ]; then
  added=0
  i=0
  for repo in $repos; do
    if helm_repo_url_exists "$repo"; then
      continue
    fi
    name="$(next_repo_name)"
    echo "helm repo add ${name} ${repo}"
    helm repo add "${name}" "${repo}"
    i=$((i + 1))
    added=1
  done
  if [ "$added" -eq 1 ]; then
    helm repo update
  fi
fi

for chart in $charts; do
  chart_file="$chart/Chart.yaml"
  [ -f "$chart_file" ] || continue
  echo "helm lint: $chart"
  if chart_uses_dhi_dependency "$chart" &&
    { [ -z "${DHI_USERNAME:-}" ] || [ -z "${DHI_PASSWORD:-}" ]; }; then
    echo "Skipping dependency build for $chart; DHI credentials are not available."
  else
    helm dependency build "$chart"
  fi
  case "$chart" in
    charts/matrix-umbrella)
      # matrix-umbrella is validated with parent values because some upstream
      # dependencies do not lint standalone with their own defaults.
      helm lint "$chart"
      ;;
    *)
      helm lint --with-subcharts "$chart"
      ;;
  esac
done
