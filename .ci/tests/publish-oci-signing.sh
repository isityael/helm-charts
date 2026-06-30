#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
publish_script="${repo_root}/.ci/publish-oci.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_workdir() {
  local workdir="$1"

  mkdir -p "$workdir/charts/demo/templates" "$workdir/bin"
  cat >"$workdir/charts/demo/Chart.yaml" <<'YAML'
apiVersion: v2
name: demo
version: 1.2.3
YAML
  cat >"$workdir/bin/helm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  registry)
    echo "helm registry $*" >>"$HELM_LOG"
    ;;
  show)
    exit 1
    ;;
  dependency)
    echo "helm dependency $*" >>"$HELM_LOG"
    ;;
  lint)
    echo "helm lint $*" >>"$HELM_LOG"
    ;;
  package)
    echo "helm package $*" >>"$HELM_LOG"
    printf 'Successfully packaged chart and saved it to: /tmp/demo-1.2.3.tgz\n'
    ;;
  push)
    echo "helm push $*" >>"$HELM_LOG"
    printf 'Pushed: ghcr.io/isityael/charts/demo:1.2.3\n' >&2
    printf 'Digest: sha256:abc123\n' >&2
    ;;
  *)
    echo "unexpected helm command: $*" >&2
    exit 1
    ;;
esac
SH
  chmod +x "$workdir/bin/helm"
}

test_publish_records_digest_reference_for_signing() {
  local workdir="${tmpdir}/records-ref"
  setup_workdir "$workdir"

  export HELM_LOG="${workdir}/helm.log"
  export PATH="${workdir}/bin:$PATH"
  export GHCR_USERNAME="test-user"
  export GHCR_TOKEN="test-token"
  unset COSIGN_PRIVATE_KEY COSIGN_PASSWORD

  (cd "$workdir" && "$publish_script")

  local refs_file="${workdir}/.ci/published-oci-refs.txt"
  [ -f "$refs_file" ] || fail "expected published refs file"
  grep -qx "ghcr.io/isityael/charts/demo@sha256:abc123" "$refs_file" \
    || fail "expected immutable digest ref in published refs file"
}

test_publish_signs_digest_reference_when_cosign_key_is_configured() {
  local workdir="${tmpdir}/signs-ref"
  setup_workdir "$workdir"
  cat >"$workdir/bin/cosign" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$COSIGN_LOG"
SH
  chmod +x "$workdir/bin/cosign"

  export HELM_LOG="${workdir}/helm.log"
  export COSIGN_LOG="${workdir}/cosign.log"
  export PATH="${workdir}/bin:$PATH"
  export GHCR_USERNAME="test-user"
  export GHCR_TOKEN="test-token"
  export COSIGN_PRIVATE_KEY="test-private-key"
  export COSIGN_PASSWORD="test-password"

  (cd "$workdir" && "$publish_script")

  grep -qx "sign --yes --key env://COSIGN_PRIVATE_KEY ghcr.io/isityael/charts/demo@sha256:abc123" "$COSIGN_LOG" \
    || fail "expected cosign to sign immutable digest ref"
}

test_publish_requires_cosign_password_with_private_key() {
  local workdir="${tmpdir}/requires-password"
  setup_workdir "$workdir"

  export HELM_LOG="${workdir}/helm.log"
  export PATH="${workdir}/bin:$PATH"
  export GHCR_USERNAME="test-user"
  export GHCR_TOKEN="test-token"
  export COSIGN_PRIVATE_KEY="test-private-key"
  unset COSIGN_PASSWORD

  if (cd "$workdir" && "$publish_script") >"${workdir}/stdout" 2>"${workdir}/stderr"; then
    fail "expected publish to fail when COSIGN_PRIVATE_KEY is set without COSIGN_PASSWORD"
  fi

  grep -q "COSIGN_PASSWORD is required" "${workdir}/stderr" \
    || fail "expected missing COSIGN_PASSWORD error"
}

test_publish_records_digest_reference_for_signing
test_publish_signs_digest_reference_when_cosign_key_is_configured
test_publish_requires_cosign_password_with_private_key

echo "publish-oci signing tests passed"
