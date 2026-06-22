#!/usr/bin/env bash
set -euo pipefail

for test_script in .ci/tests/*.sh; do
  bash "$test_script"
done
