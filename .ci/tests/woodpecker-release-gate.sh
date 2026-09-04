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

[[ "$(yq -r '[.when[] | select(.event == "push" and .branch == "main") | .path.include[] | select(. == ".woodpecker/build.yaml")] | length' "$release_workflow")" -eq 1 ]] \
  || fail "build workflow repairs must retrigger release-all for previously blocked chart changes"

[[ "$(yq -r '[.steps[] | select(.name == "repository-contracts") | .commands[] | select(. == "bash .ci/test-shell.sh")] | length' "$build_workflow")" -eq 1 ]] \
  || fail "build validation must execute the repository contract suite"

[[ "$(yq -r '[.steps[] | select(.name == "repository-contracts") | .commands[] | select(test("(^| )ripgrep( |$)"))] | length' "$build_workflow")" -eq 1 ]] \
  || fail "repository contract image must install ripgrep for rg-based checks"

[[ "$(yq -r '[.steps[] | select(.name == "repository-contracts") | .commands[] | select(test("(^| )perl( |$)"))] | length' "$build_workflow")" -eq 1 ]] \
  || fail "repository contract image must install Perl for chart-version fixtures"

[[ "$(yq -r '[.steps[] | select(.name == "repository-contracts") | .commands[] | select(test("(^| )perl-utils( |$)"))] | length' "$build_workflow")" -eq 1 ]] \
  || fail "repository contract image must install shasum for archive fixtures"

[[ "$(yq -r '[.steps[] | select(.name == "repository-contracts")] | length' "$build_workflow")" -eq 1 ]] \
  || fail "build workflow must define exactly one repository-contracts step"
repository_contract_image="$(yq -r '.steps[] | select(.name == "repository-contracts") | .image' "$build_workflow")"
[[ "$repository_contract_image" =~ ^harbor\.m0sh1\.cc/apps/k8s-lint-tools:ci-contract-[0-9a-f]{8}-[0-9]+@sha256:[0-9a-f]{64}$ ]] \
  || fail "repository contract image must use a retained immutable ci-contract artifact"

echo "Woodpecker release gating contract passed"
