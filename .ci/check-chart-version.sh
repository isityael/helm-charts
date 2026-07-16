#!/bin/sh
set -eu

base_ref="${1:-HEAD^}"
head_ref="${2:-HEAD}"

if ! git rev-parse --verify "${base_ref}^{commit}" >/dev/null 2>&1; then
  echo "cannot resolve base commit ${base_ref}" >&2
  exit 2
fi
if ! git rev-parse --verify "${head_ref}^{commit}" >/dev/null 2>&1; then
  echo "cannot resolve head commit ${head_ref}" >&2
  exit 2
fi

changed_files="$({
  git diff --name-only --diff-filter=ACDMRT "${base_ref}" "${head_ref}" -- charts/
} | awk -F/ '$1 == "charts" && NF >= 3')"

if [ -z "${changed_files}" ]; then
  exit 0
fi

charts="$(printf '%s\n' "${changed_files}" | awk -F/ '{ print $1 "/" $2 }' | sort -u)"
failed=0

for chart in ${charts}; do
  chart_file="${chart}/Chart.yaml"

  # A chart added or removed in this range has no prior/current packaged version to compare.
  if ! git cat-file -e "${base_ref}:${chart_file}" 2>/dev/null ||
    ! git cat-file -e "${head_ref}:${chart_file}" 2>/dev/null; then
    continue
  fi

  base_version="$(git show "${base_ref}:${chart_file}" | awk '/^[[:space:]]*version:[[:space:]]*/ { print $2; exit }' | tr -d '"')"
  head_version="$(git show "${head_ref}:${chart_file}" | awk '/^[[:space:]]*version:[[:space:]]*/ { print $2; exit }' | tr -d '"')"

  if [ "${base_version}" = "${head_version}" ]; then
    echo "${chart_file}: packaged chart content changed without a chart version change (${head_version:-missing})" >&2
    failed=1
  fi
done

exit "${failed}"
