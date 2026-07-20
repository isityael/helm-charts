#!/usr/bin/env bash
set -euo pipefail

config=renovate.json
pipeline_script=.ci/woodpecker-helm-lint.sh

post_upgrade_contracts="$(yq -o=json -I=0 '[.packageRules[] | select(.postUpgradeTasks != null) | {"matchManagers": .matchManagers, "matchFileNames": .matchFileNames, "postUpgradeTasks": .postUpgradeTasks}]' "$config")"
expected_post_upgrade_contracts='[{"matchManagers":["helmv3"],"matchFileNames":null,"postUpgradeTasks":{"commands":["helm dependency update {{{packageFileDir}}}"],"fileFilters":["{{{packageFileDir}}}/Chart.lock","{{{packageFileDir}}}/charts/**"],"executionMode":"update","installTools":{"helm":{}}}}]'

[[ "$post_upgrade_contracts" == "$expected_post_upgrade_contracts" ]] || {
  echo "Renovate Helm post-upgrade task contract is incomplete" >&2
  exit 1
}

grep -Fx 'bash .ci/tests/renovate-helm-archive-refresh.sh' "$pipeline_script" >/dev/null || {
  echo "Woodpecker Helm lint does not enforce the Renovate archive refresh contract" >&2
  exit 1
}

echo "ok - Renovate provisions Helm and tracks refreshed dependency archives"
