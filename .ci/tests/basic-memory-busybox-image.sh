#!/usr/bin/env bash
set -euo pipefail

chart_dir="charts/basic-memory"
expected_image="$(
  yq -r '.busyboxTools.image.repository + ":" + .busyboxTools.image.tag' \
    "${chart_dir}/values.yaml"
)"
[[ "${expected_image}" =~ ^dhi\.io/busybox:[^@]+@sha256:[0-9a-f]{64}$ ]] || {
  echo "busyboxTools image must use a digest-pinned DHI BusyBox runtime image" >&2
  exit 1
}
rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT

helm template basic-memory-busybox-test "${chart_dir}" \
  --namespace basic-memory \
  --set obsidianSync.enabled=true \
  --set obsidianSync.couchdb.existingSecret.name=basic-memory-couchdb \
  --set obsidianSync.livesync.existingSecret.name=basic-memory-livesync \
  >"${rendered}"

for init_container in basic-memory-home-init couchdb-locald-init; do
  image="$(
    yq -r "
      select(.kind == \"Deployment\") |
      .spec.template.spec.initContainers[] |
      select(.name == \"${init_container}\") |
      .image
    " "${rendered}"
  )"
  [[ "${image}" == "${expected_image}" ]] || {
    echo "${init_container} must use the digest-pinned DHI BusyBox runtime image" >&2
    exit 1
  }
done

if grep -F 'busybox:1.37' "${rendered}" >/dev/null; then
  echo "legacy Docker Hub BusyBox image remains in the rendered workload" >&2
  exit 1
fi

echo "basic-memory init containers use the digest-pinned DHI BusyBox runtime image"
