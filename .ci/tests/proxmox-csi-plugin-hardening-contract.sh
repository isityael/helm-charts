#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/proxmox-csi-plugin"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

status=0

fail() {
  echo "FAIL: $*" >&2
  status=1
}

default_render="${tmpdir}/default.yaml"
if ! helm template proxmox-csi-plugin "$chart" >"$default_render"; then
  fail "default values failed to render"
elif yq eval-all 'select(.kind == "Secret") | .metadata.name' "$default_render" | grep -q .; then
  fail "default render must not generate a Secret"
fi

default_cloud_config_type="$(
  yq eval-all '
    select(.kind == "Deployment") |
    .spec.template.spec.volumes[] |
    select(.name == "cloud-config") |
    keys | .[]
  ' "$default_render" | grep -v '^name$' || true
)"
[[ "$default_cloud_config_type" == "emptyDir" ]] ||
  fail "default cloud-config volume must not reference a generated Secret"

secret_render="${tmpdir}/existing-secret.yaml"
if ! helm template proxmox-csi-plugin "$chart" \
  --set existingConfigSecret=proxmox-csi-config \
  --set existingConfigSecretKey=cloud-config.yaml >"$secret_render"; then
  fail "existing Secret configuration failed to render"
else
  if yq eval-all 'select(.kind == "Secret") | .metadata.name' "$secret_render" | grep -q .; then
    fail "existing Secret configuration must not generate another Secret"
  fi

  secret_name="$(
    yq eval-all '
      select(.kind == "Deployment") |
      .spec.template.spec.volumes[] |
      select(.name == "cloud-config") |
      .secret.secretName
    ' "$secret_render"
  )"
  secret_key="$(
    yq eval-all '
      select(.kind == "Deployment") |
      .spec.template.spec.volumes[] |
      select(.name == "cloud-config") |
      .secret.items[0].key
    ' "$secret_render"
  )"
  cloud_config_read_only="$(
    yq eval-all '
      select(.kind == "Deployment") |
      .spec.template.spec.containers[] |
      select(.name | test("-controller$")) |
      .volumeMounts[] |
      select(.name == "cloud-config") |
      .readOnly
    ' "$secret_render"
  )"

  [[ "$secret_name" == "proxmox-csi-config" ]] || fail "existing Secret name was not preserved"
  [[ "$secret_key" == "cloud-config.yaml" ]] || fail "existing Secret key was not preserved"
  [[ "$cloud_config_read_only" == "true" ]] || fail "cloud-config mount must be read-only"
fi

marker="PROXMOX_INLINE_SECRET_MUST_NOT_RENDER"
if helm template proxmox-csi-plugin "$chart" \
  --set-string config.clusters[0].url=https://proxmox.example.test:8006/api2/json \
  --set-string config.clusters[0].token_id=automation@pve!csi \
  --set-string config.clusters[0].token_secret="$marker" \
  --set-string config.clusters[0].region=lab >"${tmpdir}/legacy-inline.yaml" \
  2>"${tmpdir}/legacy-inline.err"; then
  fail "legacy inline Proxmox credentials were accepted"
fi
if rg -q "$marker" "${tmpdir}/legacy-inline.yaml"; then
  fail "legacy inline Proxmox credential marker rendered into a manifest"
fi

for workload_kind in Deployment DaemonSet; do
  driver_probe_path="$(
    WORKLOAD_KIND="$workload_kind" yq eval-all '
      select(.kind == strenv(WORKLOAD_KIND)) |
      .spec.template.spec.containers[] |
      select(.name | test("-(controller|node)$")) |
      .livenessProbe.httpGet.path
    ' "$secret_render"
  )"
  driver_probe_port="$(
    WORKLOAD_KIND="$workload_kind" yq eval-all '
      select(.kind == strenv(WORKLOAD_KIND)) |
      .spec.template.spec.containers[] |
      select(.name | test("-(controller|node)$")) |
      .livenessProbe.httpGet.port
    ' "$secret_render"
  )"
  health_port_arg="$(
    WORKLOAD_KIND="$workload_kind" yq eval-all '
      select(.kind == strenv(WORKLOAD_KIND)) |
      .spec.template.spec.containers[] |
      select(.name == "liveness-probe") |
      .args[] |
      select(test("^--health-port="))
    ' "$secret_render"
  )"

  [[ "$driver_probe_path" == "/healthz" ]] || fail "$workload_kind CSI driver lacks /healthz probe"
  [[ "$driver_probe_port" == "healthz" ]] || fail "$workload_kind CSI driver probe lacks named healthz port"
  [[ "$health_port_arg" == "--health-port=9808" ]] ||
    fail "$workload_kind liveness sidecar does not serve port 9808"
done

if ((status != 0)); then
  exit "$status"
fi

echo "proxmox-csi-plugin hardening contract passed"
