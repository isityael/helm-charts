#!/usr/bin/env bash
set -euo pipefail

chart_dir="charts/basic-memory"
expected_image="dhi.io/busybox:1.38.0-alpine3.24@sha256:1717d1a1f11506127476d11c8cada3b702aa730bfc9213513434e153b1d0e0bc"
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
