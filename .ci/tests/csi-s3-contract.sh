#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/csi-s3"
rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT

status=0

fail() {
  echo "FAIL: $*" >&2
  status=1
}

helm template csi-s3 "$chart" >"$rendered"

secret_verbs="$(
  yq eval-all '
    select(.kind == "ClusterRole" and .metadata.name == "csi-s3-external-provisioner-runner") |
    .rules[] |
    select(.apiGroups == [""] and .resources == ["secrets"]) |
    .verbs[]
  ' "$rendered"
)"
grep -qx get <<<"$secret_verbs" || fail "provisioner ClusterRole must get Secrets"
if grep -qx list <<<"$secret_verbs"; then
  fail "provisioner ClusterRole must not list Secrets"
fi

service_name="$(yq eval-all 'select(.kind == "Service") | .metadata.name' "$rendered")"
statefulset_service_name="$(yq eval-all 'select(.kind == "StatefulSet") | .spec.serviceName' "$rendered")"
[[ -n "$service_name" && "$service_name" == "$statefulset_service_name" ]] ||
  fail "Service name ${service_name} does not match StatefulSet serviceName ${statefulset_service_name}"

node_sa_automount="$(
  yq eval-all 'select(.kind == "ServiceAccount" and .metadata.name == "csi-s3") | .automountServiceAccountToken' \
    "$rendered"
)"
[[ "$node_sa_automount" == "false" ]] || fail "node ServiceAccount must disable API token automount"

node_pod_automount="$(
  yq eval-all 'select(.kind == "DaemonSet" and .metadata.name == "csi-s3") |
    .spec.template.spec.automountServiceAccountToken' "$rendered"
)"
[[ "$node_pod_automount" == "false" ]] || fail "node pod must disable API token automount"

node_cluster_rbac_count="$(
  yq eval-all '
    select(
      (.kind == "ClusterRole" or .kind == "ClusterRoleBinding") and
      .metadata.name == "csi-s3"
    ) |
    .kind
  ' "$rendered" | grep -c . || true
)"
[[ "$node_cluster_rbac_count" == "0" ]] ||
  fail "empty bound node ClusterRole resources must not render"

if ((status != 0)); then
  exit "$status"
fi

echo "csi-s3 RBAC and service identity contract passed"
