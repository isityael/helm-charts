#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/.ci/pre-commit/chart-version-bump.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_repo() {
  local workdir="$1"
  local version="${2:-1.2.3}"

  git -C "$workdir" init -q
  git -C "$workdir" config user.email test@example.invalid
  git -C "$workdir" config user.name "Chart Version Test"

  mkdir -p "$workdir/charts/demo/charts/child" "$workdir/charts/demo/ci" "$workdir/charts/demo/templates"
  cat >"$workdir/charts/demo/Chart.yaml" <<YAML
apiVersion: v2
name: demo
version: ${version}
appVersion: "1.0.0"
YAML
  cat >"$workdir/charts/demo/values.yaml" <<'YAML'
image:
  repository: ghcr.io/example/demo
  tag: "1.0.0"
YAML
  cat >"$workdir/charts/demo/templates/deployment.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
YAML
  cat >"$workdir/charts/demo/values.schema.json" <<'JSON'
{"type":"object"}
JSON
  cat >"$workdir/charts/demo/README.md" <<'MARKDOWN'
# Demo
MARKDOWN
  cat >"$workdir/charts/demo/ci/test-values.yaml" <<'YAML'
replicaCount: 1
YAML
  cat >"$workdir/charts/demo/charts/child/values.yaml" <<'YAML'
enabled: true
YAML

  git -C "$workdir" add charts/demo
  git -C "$workdir" commit -qm "Initial chart"
}

assert_version() {
  local workdir="$1"
  local want="$2"
  local got

  got="$(awk '/^version:/ {print $2}' "$workdir/charts/demo/Chart.yaml")"
  [ "$got" = "$want" ] || fail "expected chart version ${want}, got ${got}"
}

assert_staged() {
  local workdir="$1"
  local path="$2"

  git -C "$workdir" diff --cached --name-only | grep -qx "$path" || fail "expected ${path} to be staged"
}

test_values_change_bumps_chart_version() {
  local workdir="${tmpdir}/values-change"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  sed -i.bak 's/1.0.0/1.0.1/' "$workdir/charts/demo/values.yaml"
  rm "$workdir/charts/demo/values.yaml.bak"
  git -C "$workdir" add charts/demo/values.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_template_change_bumps_chart_version() {
  local workdir="${tmpdir}/template-change"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  printf '\n  labels:\n    app: demo\n' >>"$workdir/charts/demo/templates/deployment.yaml"
  git -C "$workdir" add charts/demo/templates/deployment.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_schema_change_bumps_chart_version() {
  local workdir="${tmpdir}/schema-change"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  printf '%s\n' '{"type":"object","additionalProperties":false}' >"$workdir/charts/demo/values.schema.json"
  git -C "$workdir" add charts/demo/values.schema.json

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_app_version_change_bumps_chart_version() {
  local workdir="${tmpdir}/app-version-change"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  sed -i.bak 's/appVersion: "1.0.0"/appVersion: "1.0.1"/' "$workdir/charts/demo/Chart.yaml"
  rm "$workdir/charts/demo/Chart.yaml.bak"
  git -C "$workdir" add charts/demo/Chart.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_nested_dependency_change_bumps_chart_version() {
  local workdir="${tmpdir}/nested-dependency-change"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  sed -i.bak 's/enabled: true/enabled: false/' "$workdir/charts/demo/charts/child/values.yaml"
  rm "$workdir/charts/demo/charts/child/values.yaml.bak"
  git -C "$workdir" add charts/demo/charts/child/values.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_deleted_packaged_file_bumps_chart_version() {
  local workdir="${tmpdir}/deleted-file"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  rm "$workdir/charts/demo/templates/deployment.yaml"
  git -C "$workdir" add charts/demo/templates/deployment.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_readme_change_bumps_chart_version() {
  local workdir="${tmpdir}/readme-change"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  printf '\nInstall with Helm.\n' >>"$workdir/charts/demo/README.md"
  git -C "$workdir" add charts/demo/README.md

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_ci_asset_change_bumps_chart_version() {
  local workdir="${tmpdir}/ci-asset-change"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  sed -i.bak 's/replicaCount: 1/replicaCount: 2/' "$workdir/charts/demo/ci/test-values.yaml"
  rm "$workdir/charts/demo/ci/test-values.yaml.bak"
  git -C "$workdir" add charts/demo/ci/test-values.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_existing_chart_version_change_is_not_bumped_again() {
  local workdir="${tmpdir}/already-bumped"
  mkdir -p "$workdir"
  setup_repo "$workdir"

  sed -i.bak 's/1.0.0/1.0.1/' "$workdir/charts/demo/values.yaml"
  rm "$workdir/charts/demo/values.yaml.bak"
  sed -i.bak 's/version: 1.2.3/version: 1.2.9/' "$workdir/charts/demo/Chart.yaml"
  rm "$workdir/charts/demo/Chart.yaml.bak"
  git -C "$workdir" add charts/demo/values.yaml charts/demo/Chart.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "1.2.9"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_v_prefixed_version_is_preserved() {
  local workdir="${tmpdir}/v-prefixed"
  mkdir -p "$workdir"
  setup_repo "$workdir" "v1.2.3"

  sed -i.bak 's/1.0.0/1.0.1/' "$workdir/charts/demo/values.yaml"
  rm "$workdir/charts/demo/values.yaml.bak"
  git -C "$workdir" add charts/demo/values.yaml

  (cd "$workdir" && "$script")

  assert_version "$workdir" "v1.2.4"
  assert_staged "$workdir" "charts/demo/Chart.yaml"
}

test_values_change_bumps_chart_version
test_template_change_bumps_chart_version
test_schema_change_bumps_chart_version
test_app_version_change_bumps_chart_version
test_nested_dependency_change_bumps_chart_version
test_deleted_packaged_file_bumps_chart_version
test_readme_change_bumps_chart_version
test_ci_asset_change_bumps_chart_version
test_existing_chart_version_change_is_not_bumped_again
test_v_prefixed_version_is_preserved

echo "chart-version-bump tests passed"
