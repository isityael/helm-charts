#!/usr/bin/env bash
set -euo pipefail

found=0
while IFS= read -r path; do
  echo "Local cleanup artifact found: ${path}" >&2
  found=1
done < <(
  find . \
    \( -path ./.git -o -path ./.venv -o -path ./node_modules -o -path ./.ci/rendered \) -prune \
    -o -type f -name .DS_Store -print | sort
)

exit "${found}"
