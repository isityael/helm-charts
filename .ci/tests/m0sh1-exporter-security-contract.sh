#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/m0sh1-exporter"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

rendered="${tmpdir}/rendered.yaml"
helm template m0sh1-exporter "$chart" >"$rendered"

service_account_automount="$(
  yq eval-all '
    select(.kind == "ServiceAccount" and .metadata.name == "opnsense-exporter") |
    .automountServiceAccountToken
  ' "$rendered"
)"
[ "$service_account_automount" = "false" ] ||
  fail "shared exporter ServiceAccount must disable token automount"

for workload in opnsense-exporter prometheus-snmp-exporter prometheus-pve-exporter; do
  service_account="$(
    WORKLOAD="$workload" yq eval-all '
      select(.kind == "Deployment" and .metadata.name == strenv(WORKLOAD)) |
      .spec.template.spec.serviceAccountName
    ' "$rendered"
  )"
  [ "$service_account" = "opnsense-exporter" ] ||
    fail "${workload} must use the shared restricted ServiceAccount"
done

opnsense_automount="$(
  yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "opnsense-exporter") |
    .spec.template.spec.automountServiceAccountToken
  ' "$rendered"
)"
[ "$opnsense_automount" = "false" ] || fail "opnsense-exporter pod must disable token automount"

opnsense_service_links="$(
  yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "opnsense-exporter") |
    .spec.template.spec.enableServiceLinks
  ' "$rendered"
)"
[ "$opnsense_service_links" = "false" ] || fail "opnsense-exporter pod must disable service links"

assert_restricted_container() {
  local workload="$1"
  local container="$2"
  local expected_uid="$3"
  local context

  context="$(
    WORKLOAD="$workload" CONTAINER="$container" yq eval-all -o=json -I=0 '
      select(.kind == "Deployment" and .metadata.name == strenv(WORKLOAD)) |
      .spec.template.spec.containers[] |
      select(.name == strenv(CONTAINER)) |
      .securityContext
    ' "$rendered"
  )"

  [ "$(yq -r '.allowPrivilegeEscalation' <<<"$context")" = "false" ] ||
    fail "${workload}/${container} must disable privilege escalation"
  [ "$(yq -r '.readOnlyRootFilesystem' <<<"$context")" = "true" ] ||
    fail "${workload}/${container} must use a read-only root filesystem"
  [ "$(yq -r '.runAsNonRoot' <<<"$context")" = "true" ] ||
    fail "${workload}/${container} must run as non-root"
  [ "$(yq -r '.runAsUser' <<<"$context")" = "$expected_uid" ] ||
    fail "${workload}/${container} must preserve UID ${expected_uid}"
  [ "$(yq -r '.capabilities.drop[]' <<<"$context")" = "ALL" ] ||
    fail "${workload}/${container} must drop all capabilities"
  [ "$(yq -r '.seccompProfile.type' <<<"$context")" = "RuntimeDefault" ] ||
    fail "${workload}/${container} must use RuntimeDefault seccomp"
}

assert_restricted_container opnsense-exporter opnsense-exporter 65534
assert_restricted_container prometheus-snmp-exporter snmp-exporter 1000
assert_restricted_container prometheus-pve-exporter pveexporter 65534

for workload in opnsense-exporter prometheus-snmp-exporter prometheus-pve-exporter; do
  probe_count="$(
    WORKLOAD="$workload" yq eval-all '
      select(.kind == "Deployment" and .metadata.name == strenv(WORKLOAD)) |
      [.spec.template.spec.containers[] | select(.livenessProbe and .readinessProbe)] |
      length
    ' "$rendered"
  )"
  [ "$probe_count" = "1" ] || fail "${workload} must retain liveness and readiness probes"

  resources_complete="$(
    WORKLOAD="$workload" yq eval-all '
      select(.kind == "Deployment" and .metadata.name == strenv(WORKLOAD)) |
      [.spec.template.spec.containers[] |
        select(.resources.requests.cpu and .resources.requests.memory and
          .resources.limits.cpu and .resources.limits.memory)] |
      length
    ' "$rendered"
  )"
  [ "$resources_complete" = "1" ] || fail "${workload} must retain CPU and memory requests and limits"
done

non_cluster_ip_services="$(
  yq eval-all '[select(.kind == "Service" and .spec.type != "ClusterIP")] | length' "$rendered"
)"
[ "$non_cluster_ip_services" = "0" ] || fail "exporter Services must remain cluster-internal"

external_routes="$(
  yq eval-all '[select(.kind == "Ingress" or .kind == "HTTPRoute" or .kind == "Route")] | length' "$rendered"
)"
[ "$external_routes" = "0" ] || fail "exporters must not expose an external route by default"

rbac_resources="$(
  yq eval-all '[select(.kind == "Role" or .kind == "RoleBinding" or .kind == "ClusterRole" or
    .kind == "ClusterRoleBinding")] | length' "$rendered"
)"
[ "$rbac_resources" = "0" ] || fail "exporters must not receive unused Kubernetes API permissions"

echo "m0sh1-exporter security contract passed"
