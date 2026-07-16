#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/csi-driver-nfs"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

rendered="${tmpdir}/rendered.yaml"
helm template csi-driver-nfs "$chart" \
  --set externalSnapshotter.enabled=true \
  --set externalSnapshotter.customResourceDefinitions.enabled=false \
  >"$rendered"

assert_automount() {
  local kind="$1"
  local name="$2"
  local expected="$3"
  local actual

  if [ "$kind" = "ServiceAccount" ]; then
    actual="$(
      RESOURCE_KIND="$kind" RESOURCE_NAME="$name" yq eval-all '
        select(.kind == strenv(RESOURCE_KIND) and .metadata.name == strenv(RESOURCE_NAME)) |
        .automountServiceAccountToken
      ' "$rendered"
    )"
  else
    actual="$(
      RESOURCE_KIND="$kind" RESOURCE_NAME="$name" yq eval-all '
        select(.kind == strenv(RESOURCE_KIND) and .metadata.name == strenv(RESOURCE_NAME)) |
        .spec.template.spec.automountServiceAccountToken
      ' "$rendered"
    )"
  fi

  [ "$actual" = "$expected" ] ||
    fail "${kind} ${name} automountServiceAccountToken: expected ${expected}, got ${actual:-<unset>}"
}

assert_restricted_container() {
  local workload_kind="$1"
  local workload_name="$2"
  local container_name="$3"
  local context

  context="$(
    RESOURCE_KIND="$workload_kind" RESOURCE_NAME="$workload_name" CONTAINER_NAME="$container_name" \
      yq eval-all -o=json -I=0 '
        select(.kind == strenv(RESOURCE_KIND) and .metadata.name == strenv(RESOURCE_NAME)) |
        .spec.template.spec.containers[] |
        select(.name == strenv(CONTAINER_NAME)) |
        .securityContext
      ' "$rendered"
  )"

  [ "$(yq -r '.allowPrivilegeEscalation' <<<"$context")" = "false" ] ||
    fail "${workload_name}/${container_name} must disable privilege escalation"
  [ "$(yq -r '.readOnlyRootFilesystem' <<<"$context")" = "true" ] ||
    fail "${workload_name}/${container_name} must use a read-only root filesystem"
  [ "$(yq -r '.runAsNonRoot' <<<"$context")" = "true" ] ||
    fail "${workload_name}/${container_name} must run as non-root"
  [ "$(yq -r '.capabilities.drop[]' <<<"$context")" = "ALL" ] ||
    fail "${workload_name}/${container_name} must drop all capabilities"
}

assert_http_liveness_probe() {
  local workload_kind="$1"
  local workload_name="$2"
  local container_name="$3"
  local path

  path="$(
    RESOURCE_KIND="$workload_kind" RESOURCE_NAME="$workload_name" CONTAINER_NAME="$container_name" \
      yq eval-all '
        select(.kind == strenv(RESOURCE_KIND) and .metadata.name == strenv(RESOURCE_NAME)) |
        .spec.template.spec.containers[] |
        select(.name == strenv(CONTAINER_NAME)) |
        .livenessProbe.httpGet.path
      ' "$rendered"
  )"

  [ "$path" = "/healthz" ] ||
    fail "${workload_name}/${container_name} must probe its configured /healthz endpoint"
}

assert_automount ServiceAccount csi-nfs-controller-sa true
assert_automount ServiceAccount csi-nfs-node-sa false
assert_automount Deployment csi-nfs-controller true
assert_automount DaemonSet csi-nfs-node false
assert_automount ServiceAccount snapshot-controller true
assert_automount Deployment snapshot-controller true

for container in csi-provisioner csi-resizer csi-snapshotter liveness-probe; do
  assert_restricted_container Deployment csi-nfs-controller "$container"
done
assert_restricted_container DaemonSet csi-nfs-node liveness-probe
assert_restricted_container DaemonSet csi-nfs-node node-driver-registrar
assert_restricted_container Deployment snapshot-controller snapshot-controller

assert_http_liveness_probe Deployment csi-nfs-controller nfs
assert_http_liveness_probe DaemonSet csi-nfs-node nfs
assert_http_liveness_probe DaemonSet csi-nfs-node node-driver-registrar

controller_nfs_privileged="$(
  yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "csi-nfs-controller") |
    .spec.template.spec.containers[] |
    select(.name == "nfs") |
    .securityContext.privileged
  ' "$rendered"
)"
[ "$controller_nfs_privileged" = "true" ] || fail "controller NFS plugin must remain privileged for mounts"

node_nfs_privileged="$(
  yq eval-all '
    select(.kind == "DaemonSet" and .metadata.name == "csi-nfs-node") |
    .spec.template.spec.containers[] |
    select(.name == "nfs") |
    .securityContext.privileged
  ' "$rendered"
)"
[ "$node_nfs_privileged" = "true" ] || fail "node NFS plugin must remain privileged for mounts"

echo "csi-driver-nfs security contract passed"
