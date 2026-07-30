#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_workflow="${repo_root}/.woodpecker/build.yaml"
release_workflow="${repo_root}/.woodpecker/release-all.yaml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ "$(yq -r '[.when[] | select(.event == "manual")] | length' "$build_workflow")" -eq 1 ]] \
  || fail "manual releases must include the build workflow"

[[ "$(yq -r '.depends_on | length' "$release_workflow")" -eq 1 ]] \
  && [[ "$(yq -r '.depends_on[0]' "$release_workflow")" == "build" ]] \
  || fail "release-all must depend on successful build validation"

echo "Woodpecker release gating contract passed"
