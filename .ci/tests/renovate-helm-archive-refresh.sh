#!/usr/bin/env bash
set -euo pipefail

config=renovate.json
pipeline_script=.ci/woodpecker-helm-lint.sh

post_upgrade_contracts="$(yq -o=json -I=0 '[.packageRules[] | select(.postUpgradeTasks != null) | {"matchManagers": .matchManagers, "matchFileNames": .matchFileNames, "postUpgradeTasks": .postUpgradeTasks}]' "$config")"
expected_post_upgrade_contracts='[{"matchManagers":["helmv3"],"matchFileNames":null,"postUpgradeTasks":{"commands":["node .ci/renovate-helm-dependency-update.mjs {{{packageFileDir}}}"],"fileFilters":["{{{packageFileDir}}}/Chart.lock","{{{packageFileDir}}}/charts/**"],"executionMode":"update","installTools":{"helm":{}}}}]'

[[ "$post_upgrade_contracts" == "$expected_post_upgrade_contracts" ]] || {
  echo "Renovate Helm post-upgrade task contract is incomplete" >&2
  exit 1
}

grep -Fx 'bash .ci/tests/renovate-helm-archive-refresh.sh' "$pipeline_script" >/dev/null || {
  echo "Woodpecker Helm lint does not enforce the Renovate archive refresh contract" >&2
  exit 1
}

grep -Fx 'bash .ci/check-helm-dependencies.sh' "$pipeline_script" >/dev/null || {
  echo "Woodpecker Helm lint does not run the dependency guard for pull requests" >&2
  exit 1
}

if grep -Fq 'Skipping Helm dependency guard; DHI credentials are not available.' "$pipeline_script"; then
  echo "Woodpecker Helm lint skips all dependency checks when only DHI credentials are unavailable" >&2
  exit 1
fi

grep -Fq 'node --test .ci/tests/renovate-helm-dependency-update.mjs' .woodpecker/build.yaml || {
  echo "Woodpecker does not enforce the Renovate Helm authentication contract" >&2
  exit 1
}

echo "ok - Renovate authenticates Helm and tracks refreshed dependency archives"
