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

test_existing_database_names_are_preserved() {
  # Live clusters already own Database resources named <cluster>-<name> with
  # "_" mapped to "-" (e.g. cnpg-main-mautrix-discord). Changing that scheme
  # would delete and recreate them, so short names must not gain a hash.
  local rendered="${tmpdir}/existing-names.yaml"
  local names

  render_databases "${rendered}" '[{"enabled":false,"ensure":"absent","name":"mautrix_discord","owner":"x"},{"enabled":true,"name":"zipline","owner":"zipline"}]'
  names="$(yq eval-all 'select(.kind == "Database") | .metadata.name' "${rendered}" | sed '/^---$/d' | sort | tr '\n' ' ')"
  [[ "${names}" == "cnpg-main-mautrix-discord cnpg-main-zipline " ]] ||
    fail "expected stable Database names, got: ${names}"
}

test_nested_dependency_renders_no_grafana_dashboard() {
  # Infra wrappers consume cnpg-stack as a dependency, which puts the
  # operator's dashboard subchart three levels deep where Helm cannot see the
  # operator chart's own condition default.
  local parent="${tmpdir}/parent"
  mkdir -p "${parent}"
  cat >"${parent}/Chart.yaml" <<YAML
apiVersion: v2
name: parent
version: 0.0.0
dependencies:
  - name: cnpg-stack
    version: "$(yq -r '.version' "${chart}/Chart.yaml")"
    repository: file://${chart}
YAML
  helm dependency build "${parent}" >/dev/null
  if helm template parent "${parent}" | yq eval-all 'select(.kind == "ConfigMap") | .metadata.name' - | grep -qx cnpg-grafana-dashboard; then
    fail "expected no cnpg-grafana-dashboard ConfigMap when cnpg-stack is a dependency"
  fi
}

test_pooler_pdb_follows_replicas() {
  local count

  count="$(helm template cnpg-stack "${chart}" --set cnpg.pgbouncer.replicas=1 | yq eval-all 'select(.kind == "PodDisruptionBudget") | .kind' - | grep -c . || true)"
  [[ "${count}" == "0" ]] || fail "expected no pooler PDB with one replica"
  count="$(helm template cnpg-stack "${chart}" --set cnpg.pgbouncer.replicas=2 | yq eval-all 'select(.kind == "PodDisruptionBudget") | .kind' - | grep -c . || true)"
  [[ "${count}" == "1" ]] || fail "expected a pooler PDB with two replicas"
  count="$(helm template cnpg-stack "${chart}" --set cnpg.pgbouncer.replicas=2 --set cnpg.pgbouncer.pdb.enabled=false | yq eval-all 'select(.kind == "PodDisruptionBudget") | .kind' - | grep -c . || true)"
  [[ "${count}" == "0" ]] || fail "expected pdb.enabled=false to suppress the pooler PDB"
}

test_cluster_scrape_is_configurable() {
  local rendered="${tmpdir}/scrape.yaml"

  helm template cnpg-stack "${chart}" \
    --set cnpg.metrics.clusterScrape.name=cnpg-cluster-metrics \
    --set cnpg.metrics.clusterScrape.instancesOnly=false \
    --set cnpg.metrics.releaseLabel=kube-prometheus-stack >"${rendered}"
  [[ "$(yq eval-all 'select(.metadata.name == "cnpg-cluster-metrics") | .kind' "${rendered}")" == "VMPodScrape" ]] ||
    fail "expected cluster scrape named by cnpg.metrics.clusterScrape.name"
  [[ "$(yq eval-all 'select(.metadata.name == "cnpg-cluster-metrics") | .spec.selector.matchLabels | has("cnpg.io/podRole")' "${rendered}")" == "false" ]] ||
    fail "expected instancesOnly=false to drop the podRole selector"
  [[ "$(yq eval-all 'select(.metadata.name == "cnpg-cluster-metrics") | .metadata.labels.release' "${rendered}")" == "kube-prometheus-stack" ]] ||
    fail "expected releaseLabel on scrape objects"
  [[ "$(helm template cnpg-stack "${chart}" --set cnpg.metrics.scrapeKind=PodMonitor | yq eval-all 'select(.metadata.name == "cnpg-main-metrics") | .kind' -)" == "PodMonitor" ]] ||
    fail "expected scrapeKind=PodMonitor to render a PodMonitor"
}

test_database_metadata_preserves_postgresql_name
test_long_database_metadata_names_remain_unique
test_operator_app_version_matches_vendored_chart
test_existing_database_names_are_preserved
test_nested_dependency_renders_no_grafana_dashboard
test_pooler_pdb_follows_replicas
test_cluster_scrape_is_configurable

if ((status != 0)); then
  exit "${status}"
fi

echo "cnpg-stack contract tests passed"
