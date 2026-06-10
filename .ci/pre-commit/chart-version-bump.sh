#!/usr/bin/env bash
set -euo pipefail

changed_files="$(git diff --cached --name-only --diff-filter=ACMRT | grep -E '^charts/[^/]+/(values[^/]*\.ya?ml|templates/.+)$' || true)"
if [ -z "$changed_files" ]; then
  exit 0
fi

charts="$(printf '%s\n' "$changed_files" | awk -F/ '{print $1"/"$2}' | sort -u)"

for chart in $charts; do
  chart_file="${chart}/Chart.yaml"
  [ -f "$chart_file" ] || continue

  if git diff --cached --unified=0 -- "$chart_file" | grep -qE '^[-+]version:[[:space:]]*'; then
    echo "chart version already staged: ${chart_file}"
    continue
  fi

  old_version="$(awk '/^[[:space:]]*version:[[:space:]]*/ {print $2; exit}' "$chart_file" | tr -d '"')"
  if ! printf '%s\n' "$old_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "cannot patch-bump ${chart_file}: unsupported version '${old_version}'" >&2
    exit 1
  fi

  IFS=. read -r major minor patch <<EOF
$old_version
EOF
  new_version="${major}.${minor}.$((patch + 1))"

  perl -0pi -e 's{^([[:space:]]*version:[[:space:]]*"?)(\d+)\.(\d+)\.(\d+)("?[[:space:]]*)$}{$1 . $2 . "." . $3 . "." . ($4 + 1) . $5}em' "$chart_file"

  git add "$chart_file"
  echo "patch-bumped ${chart_file}: ${old_version} -> ${new_version}"
done
