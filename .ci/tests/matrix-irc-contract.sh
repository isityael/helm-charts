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

archive_semantic_checksum() {
  local archive="$1"
  local extracted

  extracted="$(mktemp -d "${tmpdir}/archive.XXXXXX")"
  tar -xzf "${archive}" -C "${extracted}"
  (
    cd "${extracted}"
    find . -type f -print | LC_ALL=C sort | while IFS= read -r file; do
      shasum -a 256 "${file}"
    done | shasum -a 256 | awk '{ print $1 }'
  )
}

helm_args=(
  --set tags.matrix-appservice-irc=true
  --set global.matrixIrcContract=true
  --set matrix-appservice-irc.host=irc-media.example.test
  --set matrix-appservice-irc.homeserver.domain=example.test
  --set matrix-appservice-irc.waitForRedis.image.repository=dhi.io/busybox
  --set matrix-appservice-irc.waitForRedis.image.tag=1.38.0-alpine3.24
  --set-string "matrix-appservice-irc.waitForRedis.image.digest=${wait_digest}"
  --set matrix-appservice-irc.postgres.enabled=true
  --set matrix-appservice-irc.postgres.image.repository=dhi.io/postgres
  --set matrix-appservice-irc.postgres.image.tag=18.4-alpine3.24
  --set-string "matrix-appservice-irc.postgres.image.digest=${postgres_digest}"
  --set matrix-appservice-irc.redis.enabled=true
  --set matrix-appservice-irc.redis.image.repository=dhi.io/valkey
  --set matrix-appservice-irc.redis.image.tag=9.1.0-debian13
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
  "dhi.io/busybox:1.38.0-alpine3.24@${wait_digest}"
  "dhi.io/postgres:18.4-alpine3.24@${postgres_digest}"
  "dhi.io/valkey:9.1.0-debian13@${redis_digest}"
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

dependency_root="${tmpdir}/dependency-build"
dependency_chart="${dependency_root}/matrix-umbrella"
dependency_archive="${dependency_chart}/charts/matrix-appservice-irc-1.0.0.tgz"
mkdir -p "${dependency_root}"
cp -R "${chart}" "${dependency_chart}"
checksum_before="$(archive_semantic_checksum "${dependency_archive}")"
if ! helm dependency build --skip-refresh "${dependency_chart}" >"${tmpdir}/dependency-build.out" 2>&1; then
  fail "helm dependency build --skip-refresh failed for the isolated Matrix umbrella copy"
  sed -n '1,80p' "${tmpdir}/dependency-build.out" >&2
else
  checksum_after="$(archive_semantic_checksum "${dependency_archive}")"
  [[ "${checksum_before}" == "${checksum_after}" ]] ||
    fail "dependency build replaced the semantically patched Matrix IRC archive"
fi

if helm dependency list "${dependency_chart}" |
  awk 'NR > 1 && NF && $NF != "ok" { bad = 1 } END { exit bad ? 0 : 1 }'; then
  fail "Matrix umbrella dependency status is not ok after dependency build"
fi

if ((status != 0)); then
  exit "${status}"
fi

echo "matrix IRC vendored compatibility contract passed"
