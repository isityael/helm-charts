#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/cnpg-stack"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

status=0

fail() {
  echo "FAIL: $*" >&2
  status=1
}

render_databases() {
  local output="$1"
  local databases="$2"

  helm template cnpg-stack "${chart}" --set-json "cnpg.databases=${databases}" >"${output}"
}

test_database_metadata_preserves_postgresql_name() {
  local rendered="${tmpdir}/database.yaml"
  local metadata_name
  local spec_name

  render_databases "${rendered}" '[{"enabled":true,"name":"ci_app","owner":"app"}]'
  metadata_name="$(yq eval-all 'select(.kind == "Database") | .metadata.name' "${rendered}")"
  spec_name="$(yq eval-all 'select(.kind == "Database") | .spec.name' "${rendered}")"

  if [[ ! "${metadata_name}" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || ((${#metadata_name} > 63)); then
    fail "expected RFC1123-safe Database metadata.name, got ${metadata_name}"
  fi
  [[ "${spec_name}" == "ci_app" ]] || fail "expected Database spec.name ci_app, got ${spec_name}"
}

test_long_database_metadata_names_remain_unique() {
  local rendered="${tmpdir}/long-databases.yaml"
  local names
  local first_name
  local second_name

  render_databases "${rendered}" '[{"enabled":true,"name":"this_is_a_very_long_database_name_with_a_shared_prefix_for_collision_a","owner":"app"},{"enabled":true,"name":"this_is_a_very_long_database_name_with_a_shared_prefix_for_collision_b","owner":"app"}]'
  names="$(
    yq eval-all 'select(.kind == "Database") | .metadata.name' "${rendered}" |
      sed '/^---$/d; /^[[:space:]]*$/d'
  )"
  first_name="$(sed -n '1p' <<<"${names}")"
  second_name="$(sed -n '2p' <<<"${names}")"

  [[ "${first_name}" != "${second_name}" ]] || fail "expected long Database metadata names to remain unique"
  for name in "${first_name}" "${second_name}"; do
    if [[ ! "${name}" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || ((${#name} > 63)); then
      fail "expected long Database metadata.name to be RFC1123-safe, got ${name}"
    fi
  done
}

test_operator_app_version_matches_vendored_chart() {
  local dependency_version
  local vendored_chart
  local wrapper_app_version
  local operator_app_version

  dependency_version="$(yq -r '.dependencies[] | select(.name == "cloudnative-pg-chart") | .version' "${chart}/Chart.yaml")"
  vendored_chart="${chart}/charts/cloudnative-pg-chart-${dependency_version}.tgz"
  wrapper_app_version="$(yq -r '.appVersion' "${chart}/Chart.yaml")"
  operator_app_version="$(tar -xOf "${vendored_chart}" cloudnative-pg-chart/Chart.yaml | yq -r '.appVersion')"

  [[ "${wrapper_app_version}" == "${operator_app_version}" ]] ||
    fail "expected Chart appVersion ${operator_app_version}, got ${wrapper_app_version}"
}

test_database_metadata_preserves_postgresql_name
test_long_database_metadata_names_remain_unique
test_operator_app_version_matches_vendored_chart

if ((status != 0)); then
  exit "${status}"
fi

echo "cnpg-stack contract tests passed"
