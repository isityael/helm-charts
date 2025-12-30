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
for chart in $charts; do
  chart_file="$chart/Chart.yaml"
  [ -f "$chart_file" ] || continue
  echo "helm lint: $chart"
  helm dependency build "$chart"
  helm lint "$chart"
done
