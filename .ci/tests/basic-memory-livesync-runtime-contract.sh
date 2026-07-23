#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart_dir="${repo_root}/charts/basic-memory"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

rendered="${tmpdir}/livesync.yaml"
helm template basic-memory "${chart_dir}" \
  -f "${chart_dir}/ci/full-stack-values.yaml" >"${rendered}"

livesync_container="$(
  yq eval-all -o=json -I=0 '
    select(.kind == "Deployment") |
    .spec.template.spec.containers[] |
    select(.name == "livesync-bridge")
  ' "${rendered}"
)"
[ -n "${livesync_container}" ] || fail "full-stack CI values must render the LiveSync container"

expected_image="ghcr.io/isityael/livesync-bridge:sha-6b9136ee311c95b276f8958d9667fa5c192d18a3@sha256:67bd36ff6e8119420010f1ed4289107a5d3cab76d06a8c9972295c0c05551e7b"
[ "$(yq -r '.image' <<<"${livesync_container}")" = "${expected_image}" ] ||
  fail "LiveSync must use the deployed immutable GHCR image"

state_dir="$(yq -r '.env[] | select(.name == "LSB_STATE_DIR") | .value' <<<"${livesync_container}")"
[ "${state_dir}" = "/app/data/.livesync-state" ] ||
  fail "LiveSync state must persist under the Basic Memory data mount"

health_port="$(yq -r '.env[] | select(.name == "LSB_HEALTH_PORT") | .value' <<<"${livesync_container}")"
[ "${health_port}" = "8080" ] || fail "LiveSync must configure its health endpoint port"

data_mount="$(yq -r '.volumeMounts[] | select(.name == "data") | .mountPath' <<<"${livesync_container}")"
[ "${data_mount}" = "/app/data" ] || fail "LiveSync state must use the existing Basic Memory data volume"

data_volume="$(
  yq -o=json -I=0 '
    select(.kind == "Deployment") |
    .spec.template.spec.volumes[] |
    select(.name == "data")
  ' "${rendered}"
)"
[ "$(yq -r '.persistentVolumeClaim.claimName' <<<"${data_volume}")" = "basic-memory-data" ] ||
  fail "full-stack CI values must retain the data PVC for LiveSync state"

command="$(yq -o=json -I=0 '.command' <<<"${livesync_container}")"
[ "${command}" = '["node","/app/dist/main.js"]' ] ||
  fail "LiveSync must run directly so Kubernetes observes process failures"

for probe in startupProbe readinessProbe livenessProbe; do
  path="$(yq -r ".${probe}.httpGet.path" <<<"${livesync_container}")"
  port="$(yq -r ".${probe}.httpGet.port" <<<"${livesync_container}")"
  [ "${path}" = "/healthz" ] || fail "LiveSync ${probe} must call /healthz"
  [ "${port}" = "8080" ] || fail "LiveSync ${probe} must use the health endpoint port"
done

[ "$(yq -r '.startupProbe.periodSeconds' <<<"${livesync_container}")" = "5" ] ||
  fail "LiveSync startup probe overrides must render"
[ "$(yq -r '.livenessProbe.periodSeconds' <<<"${livesync_container}")" = "15" ] ||
  fail "LiveSync liveness probe overrides must render"

config_map="$(
  yq eval-all -o=json -I=0 '
    select(.kind == "ConfigMap" and .metadata.name == "basic-memory-livesync-config")
  ' "${rendered}"
)"
ignore_paths="$(yq -o=json -I=0 '.data["config.json"] | fromjson | .peers[].ignorePaths' <<<"${config_map}")"
grep -Fq '".livesync-state"' <<<"${ignore_paths}" ||
  fail "LiveSync must ignore its persistent state directory"
grep -Fq '".livesync-state/**"' <<<"${ignore_paths}" ||
  fail "LiveSync must ignore nested state files"

if helm template basic-memory "${chart_dir}" --set unsupportedTopLevel=true >/dev/null 2>&1; then
  fail "values schema must reject unknown top-level values"
fi

if helm template basic-memory "${chart_dir}" \
  --set obsidianSync.enabled=true \
  --set persistence.enabled=false >/dev/null 2>&1; then
  fail "LiveSync must reject ephemeral checkpoint storage"
fi

echo "basic-memory LiveSync runtime contract passed"
