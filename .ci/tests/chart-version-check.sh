#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/.ci/check-chart-version.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_repo() {
  local workdir="$1"

  git -C "${workdir}" init -q
  git -C "${workdir}" config user.email test@example.invalid
  git -C "${workdir}" config user.name "Chart Version Check Test"
  mkdir -p "${workdir}/charts/demo/charts/child" "${workdir}/charts/demo/ci" \
    "${workdir}/charts/demo/templates"
  cat >"${workdir}/charts/demo/Chart.yaml" <<'YAML'
apiVersion: v2
name: demo
version: 1.2.3
appVersion: "1.0.0"
YAML
  cat >"${workdir}/charts/demo/values.yaml" <<'YAML'
replicaCount: 1
YAML
  cat >"${workdir}/charts/demo/values.schema.json" <<'JSON'
{"type":"object"}
JSON
  cat >"${workdir}/charts/demo/templates/deployment.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
YAML
  cat >"${workdir}/charts/demo/charts/child/values.yaml" <<'YAML'
enabled: true
YAML
  cat >"${workdir}/charts/demo/ci/test-values.yaml" <<'YAML'
replicaCount: 1
YAML
  printf '# Demo\n' >"${workdir}/charts/demo/README.md"
  git -C "${workdir}" add .
  git -C "${workdir}" commit -qm "Initial chart"
}

commit_all() {
  local workdir="$1"
  local message="$2"

  git -C "${workdir}" add -A
  git -C "${workdir}" commit -qm "${message}"
}

expect_check_failure() {
  local workdir="$1"
  local output

  if output="$(cd "${workdir}" && "${script}" 2>&1)"; then
    fail "expected chart version check to fail in ${workdir}"
  fi
  grep -q 'charts/demo/Chart.yaml' <<<"${output}" ||
    fail "expected failure to identify charts/demo/Chart.yaml, got: ${output}"
}

expect_check_success() {
  local workdir="$1"
  local output

  output="$(cd "${workdir}" && "${script}" 2>&1)" ||
    fail "expected chart version check to pass in ${workdir}, got: ${output}"
}

test_schema_change_requires_version_bump() {
  local workdir="${tmpdir}/schema"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  printf '%s\n' '{"type":"object","additionalProperties":false}' >"${workdir}/charts/demo/values.schema.json"
  commit_all "${workdir}" "Change schema"
  expect_check_failure "${workdir}"
}

test_app_version_change_requires_version_bump() {
  local workdir="${tmpdir}/app-version"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  sed -i.bak 's/appVersion: "1.0.0"/appVersion: "1.0.1"/' "${workdir}/charts/demo/Chart.yaml"
  rm "${workdir}/charts/demo/Chart.yaml.bak"
  commit_all "${workdir}" "Change app version"
  expect_check_failure "${workdir}"
}

test_nested_dependency_change_requires_version_bump() {
  local workdir="${tmpdir}/nested"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  sed -i.bak 's/enabled: true/enabled: false/' "${workdir}/charts/demo/charts/child/values.yaml"
  rm "${workdir}/charts/demo/charts/child/values.yaml.bak"
  commit_all "${workdir}" "Change nested dependency"
  expect_check_failure "${workdir}"
}

test_deletion_requires_version_bump() {
  local workdir="${tmpdir}/deletion"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  rm "${workdir}/charts/demo/templates/deployment.yaml"
  commit_all "${workdir}" "Delete template"
  expect_check_failure "${workdir}"
}

test_readme_change_requires_version_bump() {
  local workdir="${tmpdir}/readme"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  printf '\nInstall with Helm.\n' >>"${workdir}/charts/demo/README.md"
  commit_all "${workdir}" "Change README"
  expect_check_failure "${workdir}"
}

test_ci_asset_change_requires_version_bump() {
  local workdir="${tmpdir}/asset"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  sed -i.bak 's/replicaCount: 1/replicaCount: 2/' "${workdir}/charts/demo/ci/test-values.yaml"
  rm "${workdir}/charts/demo/ci/test-values.yaml.bak"
  commit_all "${workdir}" "Change CI asset"
  expect_check_failure "${workdir}"
}

test_explicit_version_bump_passes() {
  local workdir="${tmpdir}/explicit-bump"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  sed -i.bak 's/replicaCount: 1/replicaCount: 2/' "${workdir}/charts/demo/values.yaml"
  rm "${workdir}/charts/demo/values.yaml.bak"
  sed -i.bak 's/version: 1.2.3/version: 1.2.4/' "${workdir}/charts/demo/Chart.yaml"
  rm "${workdir}/charts/demo/Chart.yaml.bak"
  commit_all "${workdir}" "Bump chart version"
  expect_check_success "${workdir}"
}

test_non_chart_change_passes() {
  local workdir="${tmpdir}/non-chart"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  mkdir -p "${workdir}/notes"
  printf 'no chart change\n' >"${workdir}/notes/example.txt"
  commit_all "${workdir}" "Change non-chart file"
  expect_check_success "${workdir}"
}

test_new_chart_passes() {
  local workdir="${tmpdir}/new-chart"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  mkdir -p "${workdir}/charts/new-chart/templates"
  printf 'apiVersion: v2\nname: new-chart\nversion: 0.1.0\n' >"${workdir}/charts/new-chart/Chart.yaml"
  printf 'replicaCount: 1\n' >"${workdir}/charts/new-chart/values.yaml"
  commit_all "${workdir}" "Add chart"
  expect_check_success "${workdir}"
}

test_deleted_chart_passes() {
  local workdir="${tmpdir}/deleted-chart"
  mkdir -p "${workdir}"
  setup_repo "${workdir}"
  rm -rf "${workdir}/charts/demo"
  commit_all "${workdir}" "Delete chart"
  expect_check_success "${workdir}"
}

test_shallow_ci_clone_deepens_current_ref() {
  local source_repo="${tmpdir}/shallow-source"
  local remote_repo="${tmpdir}/shallow-remote.git"
  local workdir="${tmpdir}/shallow-clone"
  local output

  mkdir -p "${source_repo}"
  setup_repo "${source_repo}"
  sed -i.bak 's/replicaCount: 1/replicaCount: 2/' "${source_repo}/charts/demo/values.yaml"
  rm "${source_repo}/charts/demo/values.yaml.bak"
  sed -i.bak 's/version: 1.2.3/version: 1.2.4/' "${source_repo}/charts/demo/Chart.yaml"
  rm "${source_repo}/charts/demo/Chart.yaml.bak"
  commit_all "${source_repo}" "Bump chart version"

  git init -q --bare "${remote_repo}"
  git -C "${source_repo}" remote add origin "${remote_repo}"
  git -C "${source_repo}" push -q -u origin HEAD:main
  git --git-dir="${remote_repo}" symbolic-ref HEAD refs/heads/main
  git clone -q --depth=1 "file://${remote_repo}" "${workdir}"

  output="$(
    cd "${workdir}"
    CI=woodpecker CI_COMMIT_REF=refs/heads/main "${script}" 2>&1
  )" || fail "expected shallow CI checkout to deepen and pass, got: ${output}"
}

test_ci_uses_check_only_version_gates() {
  local pipeline="${repo_root}/.woodpecker/build.yaml"

  grep -q '\.ci/check-chart-version\.sh' "${pipeline}" ||
    fail "expected Woodpecker to run the local check-only chart version guard"
  if grep -q 'chart-version-guard bump.*--write' "${pipeline}"; then
    fail "Woodpecker must not auto-write chart versions"
  fi
  grep -q 'chart-version-guard check --ci woodpecker --repo \.' "${pipeline}" ||
    fail "expected external chart-version-guard check to remain enabled"
}

[[ -x "${script}" ]] || fail "expected executable check-only script ${script}"

test_schema_change_requires_version_bump
test_app_version_change_requires_version_bump
test_nested_dependency_change_requires_version_bump
test_deletion_requires_version_bump
test_readme_change_requires_version_bump
test_ci_asset_change_requires_version_bump
test_explicit_version_bump_passes
test_non_chart_change_passes
test_new_chart_passes
test_deleted_chart_passes
test_shallow_ci_clone_deepens_current_ref
test_ci_uses_check_only_version_gates

echo "chart-version-check tests passed"
