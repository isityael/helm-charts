#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
publish_script="${repo_root}/.ci/publish-artifacthub-metadata.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_workdir() {
  local workdir="$1"

  mkdir -p "$workdir/charts/alpha" "$workdir/charts/bravo" "$workdir/bin"
  printf 'apiVersion: v2\nname: alpha\nversion: 1.0.0\n' >"$workdir/charts/alpha/Chart.yaml"
  printf 'apiVersion: v2\nmaintainers:\n  - name: maintainer\nname: bravo\nversion: 2.0.0\n' \
    >"$workdir/charts/bravo/Chart.yaml"
  cat >"$workdir/artifacthub-repo.yml" <<'YAML'
repositoryID: legacy-http-repository-id
owners:
  - name: test-owner
    email: owner@example.com
YAML
  cat >"$workdir/bin/oras" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = login ]; then
  IFS= read -r password
  printf 'password=%s\n' "$password" >>"$ORAS_LOG"
fi
if [ "$1" = push ]; then
  layer="${!#}"
  cp "${layer%%:*}" "${ORAS_PAYLOADS_DIR}/$(basename "$2").yml"
fi
printf '%s\n' "$*" >>"$ORAS_LOG"
SH
  chmod +x "$workdir/bin/oras"
}

test_publishes_metadata_for_every_chart_repository() {
  local workdir="${tmpdir}/publishes-all"
  setup_workdir "$workdir"

  (
    cd "$workdir"
    ORAS_LOG="${workdir}/oras.log" \
      ORAS_PAYLOADS_DIR="$workdir" \
      PATH="${workdir}/bin:${PATH}" \
      GHCR_USERNAME="test-user" \
      GHCR_TOKEN="test-token" \
      "$publish_script"
  )

  grep -Fxq 'password=test-token' "${workdir}/oras.log" || fail "expected token on oras standard input"
  grep -Fxq 'login ghcr.io --username test-user --password-stdin' "${workdir}/oras.log" \
    || fail "expected GHCR login"
  local expected_alpha='push ghcr.io/isityael/charts/alpha:artifacthub.io'
  expected_alpha+=' --config /dev/null:application/vnd.cncf.artifacthub.config.v1+yaml'
  local expected_bravo='push ghcr.io/isityael/charts/bravo:artifacthub.io'
  expected_bravo+=' --config /dev/null:application/vnd.cncf.artifacthub.config.v1+yaml'
  grep -F "$expected_alpha" "${workdir}/oras.log" \
    | grep -F '/artifacthub-repo-oci.' \
    | grep -Fq ':application/vnd.cncf.artifacthub.repository-metadata.layer.v1.yaml' \
    || fail "expected metadata push for alpha"
  grep -F "$expected_bravo" "${workdir}/oras.log" \
    | grep -F '/artifacthub-repo-oci.' \
    | grep -Fq ':application/vnd.cncf.artifacthub.repository-metadata.layer.v1.yaml' \
    || fail "expected metadata push for bravo"
  for payload in \
    "${workdir}/alpha:artifacthub.io.yml" \
    "${workdir}/bravo:artifacthub.io.yml"; do
    grep -Fxq 'owners:' "$payload" || fail "expected owners in OCI metadata payload"
    grep -Fq 'name: test-owner' "$payload" || fail "expected owner details in OCI metadata payload"
    if grep -Fq 'legacy-http-repository-id' "$payload"; then
      fail "legacy HTTP repository ID leaked into OCI metadata payload"
    fi
    if grep -q '^repositoryID:' "$payload"; then
      fail "repositoryID must not be present in OCI metadata payload"
    fi
  done
}

test_requires_repository_metadata() {
  local workdir="${tmpdir}/missing-metadata"
  setup_workdir "$workdir"
  : >"${workdir}/artifacthub-repo.yml"

  if (
    cd "$workdir"
    PATH="${workdir}/bin:${PATH}" GHCR_USERNAME=test-user GHCR_TOKEN=test-token "$publish_script"
  ) >"${workdir}/stdout" 2>"${workdir}/stderr"; then
    fail "expected empty repository metadata to fail"
  fi
  grep -Fq 'metadata file is missing or empty' "${workdir}/stderr" \
    || fail "expected missing metadata error"
}

test_publishes_metadata_for_every_chart_repository
test_requires_repository_metadata

echo "Artifact Hub OCI metadata publishing tests passed"
