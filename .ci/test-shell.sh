#!/usr/bin/env bash
set -euo pipefail

bash .ci/check-local-artifacts.sh

for test_script in .ci/tests/*.sh; do
  bash "$test_script"
done
