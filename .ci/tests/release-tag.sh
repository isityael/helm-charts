#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
release_script="${repo_root}/.ci/release-tag.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_workdir() {
  local workdir="$1"

  mkdir -p "$workdir/.ci" "$workdir/bin" "$workdir/charts/example-chart/templates"
  cp "$release_script" "$workdir/.ci/release-tag.sh"
  cat >"$workdir/charts/example-chart/Chart.yaml" <<'YAML'
apiVersion: v2
name: example-chart
version: 1.2.3
YAML
  cat >"$workdir/bin/helm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$HELM_LOG"

case "$1" in
  registry)
    [ "${2:-}" = "login" ] || exit 2
    cat >/dev/null
    ;;
  show)
    [ "${HELM_OCI_EXISTS:-0}" = "1" ] || exit 1
    ;;
  pull)
    ref="$2"
    version=""
    destination="."
    shift 2
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --version)
          version="$2"
          shift 2
          ;;
        --destination)
          destination="$2"
          shift 2
          ;;
        *)
          exit 2
          ;;
      esac
    done
    mkdir -p "$destination"
    : >"${destination}/${ref##*/}-${version}.tgz"
    ;;
  package|push)
    echo "forbidden Helm command: $1" >&2
    exit 99
    ;;
  *)
    echo "unexpected Helm command: $*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "$workdir/.ci/release-tag.sh" "$workdir/bin/helm"
}

run_release() {
  local workdir="$1"
  local tag="$2"
  local oci_exists="${3:-1}"

  HELM_LOG="${workdir}/helm.log" \
    HELM_OCI_EXISTS="$oci_exists" \
    GHCR_USERNAME="test-user" \
    GHCR_TOKEN="test-token" \
    CI_COMMIT_TAG="$tag" \
    PATH="${workdir}/bin:$PATH" \
    "$workdir/.ci/release-tag.sh"
}

assert_release_fails() {
  local workdir="$1"
  local tag="$2"
  local oci_exists="${3:-1}"

  if run_release "$workdir" "$tag" "$oci_exists" >"${workdir}/stdout" 2>"${workdir}/stderr"; then
    fail "expected tag ${tag} to fail"
  fi
}

test_valid_tag_pulls_exact_existing_oci_artifact() {
  local workdir="${tmpdir}/valid"
  setup_workdir "$workdir"

  (cd "$workdir" && run_release "$workdir" "example-chart-v1.2.3")

  grep -Fxq "show chart oci://ghcr.io/isityael/charts/example-chart --version 1.2.3" \
    "$workdir/helm.log" || fail "expected exact OCI version lookup"
  grep -Fxq "pull oci://ghcr.io/isityael/charts/example-chart --version 1.2.3 --destination release-artifacts" \
    "$workdir/helm.log" || fail "expected exact OCI artifact pull"
  [ -f "$workdir/release-artifacts/example-chart-1.2.3.tgz" ] \
    || fail "expected pulled release artifact"
  if grep -Eq '^(package|push)( |$)' "$workdir/helm.log"; then
    fail "release script must not package or push"
  fi
}

test_mismatched_version_fails() {
  local workdir="${tmpdir}/mismatched"
  setup_workdir "$workdir"

  (cd "$workdir" && assert_release_fails "$workdir" "example-chart-v1.2.4")
}

test_malformed_tag_fails() {
  local workdir="${tmpdir}/malformed"
  setup_workdir "$workdir"

  (cd "$workdir" && assert_release_fails "$workdir" "example-chart-1.2.3")
}

test_unknown_chart_fails() {
  local workdir="${tmpdir}/unknown"
  setup_workdir "$workdir"

  (cd "$workdir" && assert_release_fails "$workdir" "unknown-chart-v1.2.3")
}

test_missing_oci_version_fails() {
  local workdir="${tmpdir}/missing-oci"
  setup_workdir "$workdir"

  (cd "$workdir" && assert_release_fails "$workdir" "example-chart-v1.2.3" 0)
}

[ -f "$release_script" ] || fail "release implementation is missing: ${release_script}"

test_valid_tag_pulls_exact_existing_oci_artifact
test_mismatched_version_fails
test_malformed_tag_fails
test_unknown_chart_fails
test_missing_oci_version_fails

echo "release-tag tests passed"
