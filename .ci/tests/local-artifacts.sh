#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/.ci/check-local-artifacts.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}" /tmp/local-artifacts.out' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

test_fails_on_ds_store_even_when_ignored() {
  local workdir="${tmpdir}/ds-store"
  mkdir -p "${workdir}/.ci"
  printf '%s\n' '.DS_Store' >"${workdir}/.gitignore"
  : >"${workdir}/.ci/.DS_Store"

  if (cd "$workdir" && "$script") >/tmp/local-artifacts.out 2>&1; then
    fail "expected .DS_Store to fail cleanup guard"
  fi

  grep -q "Local cleanup artifact found: ./.ci/.DS_Store" /tmp/local-artifacts.out ||
    fail "expected output to name ignored .DS_Store"
}

test_passes_without_local_artifacts() {
  local workdir="${tmpdir}/clean"
  mkdir -p "${workdir}/.ci"
  (cd "$workdir" && "$script") >/tmp/local-artifacts.out 2>&1 ||
    fail "expected clean workdir to pass"
}

test_fails_on_ds_store_even_when_ignored
test_passes_without_local_artifacts

echo "local artifact tests passed"
