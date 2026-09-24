#!/usr/bin/env bash
set -euo pipefail

bash .ci/check-local-artifacts.sh

# Full runs (push, or PRs touching shared CI inputs) execute every test; a PR
# that only touches charts runs the tests that reference those charts.
# Command substitution (not <(...)) so a helper failure aborts under set -e.
selected_list="$(bash .ci/changed-charts.sh)"
mapfile -t selected <<<"${selected_list}"
[ -n "${selected_list}" ] || selected=()
total="$(find charts -mindepth 2 -maxdepth 2 -name Chart.yaml | wc -l | tr -d ' ')"

ran=0
skipped=0
for test_script in .ci/tests/*.sh; do
  run=0
  if [ "${#selected[@]}" -eq "${total}" ]; then
    run=1
  else
    for chart in "${selected[@]}"; do
      if grep -qF "${chart}" "${test_script}"; then
        run=1
        break
      fi
    done
  fi
  if [ "${run}" -eq 1 ]; then
    bash "$test_script"
    ran=$((ran + 1))
  else
    skipped=$((skipped + 1))
  fi
done
echo "test-shell: ran ${ran}, skipped ${skipped} unaffected"
