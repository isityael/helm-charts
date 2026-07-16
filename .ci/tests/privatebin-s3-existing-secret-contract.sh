#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart_dir="${repo_root}/charts/privatebin"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

status=0

fail() {
  echo "FAIL: $*" >&2
  status=1
}

render_s3() {
  local output="$1"
  shift

  helm template privatebin "${chart_dir}" \
    --set storage.backend=s3 \
    --set storage.s3.endpoint=https://s3.example.test \
    --set storage.s3.bucket=privatebin \
    "$@" >"${output}"
}

valid_render="${tmpdir}/valid.yaml"
if ! render_s3 "${valid_render}" --set storage.s3.existingSecret.name=privatebin-s3; then
  fail "S3 render with a complete existingSecret contract failed"
else
  if awk '/^kind: ConfigMap$/{in_config=1} /^---$/{in_config=0} in_config' "${valid_render}" \
    | grep -Eq '^[[:space:]]*(accesskey|secretkey)[[:space:]]*='; then
    fail "S3 credentials rendered into the ConfigMap"
  fi

  grep -q 'name: AWS_ACCESS_KEY_ID' "${valid_render}" || fail "AWS access key environment reference is missing"
  grep -q 'name: AWS_SECRET_ACCESS_KEY' "${valid_render}" || fail "AWS secret key environment reference is missing"
  grep -q 'name: privatebin-s3' "${valid_render}" || fail "existing Secret name is missing from the Deployment"
fi

if render_s3 "${tmpdir}/missing-secret.yaml" 2>"${tmpdir}/missing-secret.err"; then
  fail "S3 render accepted a missing existingSecret name"
elif ! grep -q 'storage.s3.existingSecret.name' "${tmpdir}/missing-secret.err"; then
  fail "missing existingSecret failure did not identify storage.s3.existingSecret.name"
fi

if render_s3 "${tmpdir}/missing-access-key-name.yaml" \
  --set storage.s3.existingSecret.name=privatebin-s3 \
  --set-string storage.s3.existingSecret.accessKeyKey= \
  2>"${tmpdir}/missing-access-key-name.err"; then
  fail "S3 render accepted an empty existingSecret accessKeyKey"
fi

if render_s3 "${tmpdir}/missing-secret-key-name.yaml" \
  --set storage.s3.existingSecret.name=privatebin-s3 \
  --set-string storage.s3.existingSecret.secretKeyKey= \
  2>"${tmpdir}/missing-secret-key-name.err"; then
  fail "S3 render accepted an empty existingSecret secretKeyKey"
fi

if render_s3 "${tmpdir}/legacy-inline.yaml" \
  --set storage.s3.existingSecret.name=privatebin-s3 \
  --set storage.s3.accessKey=inline-access \
  --set storage.s3.secretKey=inline-secret \
  2>"${tmpdir}/legacy-inline.err"; then
  fail "legacy inline S3 credential values were accepted"
fi

printf '  AcCeSsKeY   = "inline-access"\n' >"${tmpdir}/access-key-extra.ini"
if render_s3 "${tmpdir}/access-key-extra.yaml" \
  --set storage.s3.existingSecret.name=privatebin-s3 \
  --set-file config.extra="${tmpdir}/access-key-extra.ini" \
  2>"${tmpdir}/access-key-extra.err"; then
  fail "S3 config.extra accepted an accesskey credential assignment"
fi

printf '\tSeCrEtKeY = "inline-secret"\n' >"${tmpdir}/secret-key-extra.ini"
if render_s3 "${tmpdir}/secret-key-extra.yaml" \
  --set storage.s3.existingSecret.name=privatebin-s3 \
  --set-file config.extra="${tmpdir}/secret-key-extra.ini" \
  2>"${tmpdir}/secret-key-extra.err"; then
  fail "S3 config.extra accepted a secretkey credential assignment"
fi

render_s3 "${tmpdir}/config-a.yaml" \
  --set storage.s3.existingSecret.name=privatebin-s3 \
  --set config.name=PrivateBin-A
render_s3 "${tmpdir}/config-b.yaml" \
  --set storage.s3.existingSecret.name=privatebin-s3 \
  --set config.name=PrivateBin-B

checksum_a="$(yq -r 'select(.kind == "Deployment") | .spec.template.metadata.annotations."checksum/config" // ""' \
  "${tmpdir}/config-a.yaml")"
checksum_b="$(yq -r 'select(.kind == "Deployment") | .spec.template.metadata.annotations."checksum/config" // ""' \
  "${tmpdir}/config-b.yaml")"

[[ "${checksum_a}" =~ ^[a-f0-9]{64}$ ]] || fail "Deployment is missing a deterministic checksum/config annotation"
[[ "${checksum_b}" =~ ^[a-f0-9]{64}$ ]] || fail "changed config is missing a deterministic checksum/config annotation"
[[ -n "${checksum_a}" && "${checksum_a}" != "${checksum_b}" ]] \
  || fail "checksum/config did not change when generated configuration changed"

chart_app_version="$(yq -r '.appVersion' "${chart_dir}/Chart.yaml")"
configured_app_version="$(yq -r '.image.tag | split("@")[0]' "${chart_dir}/values.yaml")"
[[ "${chart_app_version}" == "${configured_app_version}" ]] \
  || fail "Chart appVersion ${chart_app_version} does not match default image version ${configured_app_version}"

if ((status != 0)); then
  exit "${status}"
fi

echo "PrivateBin S3 existing Secret contract passed"
