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

repos=$(for chart in $charts; do
  chart_file="$chart/Chart.yaml"
  [ -f "$chart_file" ] || continue
  grep -E '^[[:space:]]*repository:[[:space:]]+https?://' "$chart_file" | awk '{print $2}'
done | sort -u)

if [ -n "$repos" ]; then
  added=0
  i=0
  for repo in $repos; do
    if helm repo list 2>/dev/null | awk 'NR>1 {print $2}' | grep -qx "$repo"; then
      continue
    fi
    name="repo-${i}"
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
  helm dependency build "$chart"
  helm lint --with-subcharts "$chart"
done
