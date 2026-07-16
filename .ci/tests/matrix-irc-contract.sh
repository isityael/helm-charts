#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/matrix-umbrella"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

status=0
rendered="${tmpdir}/rendered.yaml"
lint_output="${tmpdir}/lint.out"
render_output="${tmpdir}/render.out"
wait_digest="sha256:1111111111111111111111111111111111111111111111111111111111111111"
postgres_digest="sha256:2222222222222222222222222222222222222222222222222222222222222222"
redis_digest="sha256:3333333333333333333333333333333333333333333333333333333333333333"

fail() {
  echo "FAIL: $*" >&2
  status=1
}

helm_args=(
  --set tags.matrix-appservice-irc=true
  --set global.matrixIrcContract=true
  --set matrix-appservice-irc.host=irc-media.example.test
  --set matrix-appservice-irc.homeserver.domain=example.test
  --set-string "matrix-appservice-irc.waitForRedis.image.digest=${wait_digest}"
  --set-string "matrix-appservice-irc.postgres.image.digest=${postgres_digest}"
  --set-string "matrix-appservice-irc.redis.image.digest=${redis_digest}"
)

if ! helm lint "${chart}" "${helm_args[@]}" >"${lint_output}" 2>&1; then
  fail "IRC-enabled Helm lint rejected compatible global or sibling digest values"
  sed -n '1,80p' "${lint_output}" >&2
fi

if ! helm template matrix-irc "${chart}" "${helm_args[@]}" >"${rendered}" 2>"${render_output}"; then
  fail "IRC-enabled Helm render rejected compatible global or sibling digest values"
  sed -n '1,80p' "${render_output}" >&2
fi

# Render past the known schema defect so the same red test also exercises image helpers.
helm template matrix-irc "${chart}" "${helm_args[@]}" --skip-schema-validation >"${rendered}"
images="$(
  yq eval-all -r '.. | select(type == "!!map" and has("image")) | .image' "${rendered}" |
    sed '/^---$/d; /^[[:space:]]*$/d'
)"

expected_images=(
  "busybox:1.36@${wait_digest}"
  "postgres:16-alpine@${postgres_digest}"
  "redis:7-alpine@${redis_digest}"
)

for expected in "${expected_images[@]}"; do
  grep -Fxq "${expected}" <<<"${images}" || fail "expected rendered image ${expected}"
done

while IFS= read -r image; do
  separator_count="$(awk -F'@' '{ print NF - 1 }' <<<"${image}")"
  if ((separator_count > 1)); then
    fail "rendered image contains more than one @ separator: ${image}"
  fi
done <<<"${images}"

if ((status != 0)); then
  exit "${status}"
fi

echo "matrix IRC vendored compatibility contract passed"
