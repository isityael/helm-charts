#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart_dir="${repo_root}/charts/wakapi-dhi"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

rendered="${tmpdir}/wakapi.yaml"
helm template wakapi "${chart_dir}" \
  --set existingSecrets.cookieKey.secretName=wakapi-cookie-key \
  --set existingSecrets.cookieKey.key=cookie_key >"${rendered}"

deployment_env="${tmpdir}/deployment-env.yaml"
yq 'select(.kind == "Deployment") | .spec.template.spec.containers[0].env' \
  "${rendered}" >"${deployment_env}"

grep -q 'name: WAKAPI_COOKIE_KEY' "${deployment_env}"
grep -q 'name: wakapi-cookie-key' "${deployment_env}"
grep -q 'key: cookie_key' "${deployment_env}"

configmap="${tmpdir}/configmap.yaml"
yq 'select(.kind == "ConfigMap")' "${rendered}" >"${configmap}"
if grep -q 'WAKAPI_COOKIE_KEY' "${configmap}"; then
  echo "cookie key must not render into the ConfigMap" >&2
  exit 1
fi

if helm template wakapi "${chart_dir}" \
  --set existingSecrets.cookieKey.secretName=wakapi-cookie-key \
  >"${tmpdir}/incomplete.yaml" 2>"${tmpdir}/incomplete.err"; then
  echo "incomplete cookie key Secret reference was accepted" >&2
  exit 1
fi

echo "Wakapi cookie key existing Secret contract passed"
