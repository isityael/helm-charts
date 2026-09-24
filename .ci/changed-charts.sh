#!/usr/bin/env bash
# Print the chart directories (charts/<name>) a CI run needs to process.
#
# Pull requests get only the charts they touch. Everything else (push,
# manual, cron), an unknown merge base, or changes to shared CI inputs
# (.ci/, .woodpecker/, mise.toml, ct.yaml, .kube-linter.yaml) yield all charts.
set -euo pipefail

all_charts() {
  for chart in charts/*/; do
    [ -f "${chart}Chart.yaml" ] && printf '%s\n' "${chart%/}"
  done
}

if [ "${CI_PIPELINE_EVENT:-}" != "pull_request" ]; then
  all_charts
  exit 0
fi

target="${CI_COMMIT_TARGET_BRANCH:-main}"
git fetch --quiet --no-tags origin "${target}:refs/remotes/origin/${target}" 2>/dev/null || true
if ! base="$(git merge-base HEAD "origin/${target}" 2>/dev/null)"; then
  all_charts
  exit 0
fi

changed="$(git diff --name-only "${base}" HEAD)"
if grep -qE '^(\.ci/|\.woodpecker/|mise\.toml$|\.kube-linter\.yaml$)' <<<"${changed}"; then
  all_charts
  exit 0
fi

awk -F/ '$1 == "charts" && NF >= 3 { print $1 "/" $2 }' <<<"${changed}" | sort -u |
  while IFS= read -r chart; do
    [ -f "${chart}/Chart.yaml" ] && printf '%s\n' "${chart}"
  done
