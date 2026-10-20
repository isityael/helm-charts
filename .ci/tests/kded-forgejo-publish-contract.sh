#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/charts/demo" "$tmpdir/charts/kded-catalog"
printf 'apiVersion: v2\nname: demo\nversion: 1.0.0\n' >"$tmpdir/charts/demo/Chart.yaml"
printf 'apiVersion: v2\nname: kded-catalog\nversion: 0.1.1\n' >"$tmpdir/charts/kded-catalog/Chart.yaml"
printf 'owners:\n  - name: fixture\n' >"$tmpdir/artifacthub-repo.yml"
cat >"$tmpdir/bin/helm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$PUBLISH_TEST_LOG"
case "$1" in
  registry) cat >/dev/null ;;
  show) exit 1 ;;
  dependency|lint) ;;
  package) printf 'Packaged: /tmp/%s.tgz\n' "$(basename "$2")" ;;
  push) printf 'Digest: sha256:fixture\n' >&2 ;;
  *) exit 1 ;;
esac
SH
cat >"$tmpdir/bin/oras" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$PUBLISH_TEST_LOG"
if [ "$1" = login ]; then cat >/dev/null; fi
SH
chmod +x "$tmpdir/bin/helm" "$tmpdir/bin/oras"
export PATH="$tmpdir/bin:$PATH" PUBLISH_TEST_LOG="$tmpdir/publish.log"
export GHCR_USERNAME=fixture GHCR_TOKEN=fixture
export FORGEJO_PACKAGE_USERNAME=fixture FORGEJO_PACKAGE_TOKEN=fixture
unset COSIGN_PRIVATE_KEY COSIGN_PASSWORD
(
  cd "$tmpdir"
  bash "$repo_root/.ci/publish-oci.sh"
  bash "$repo_root/.ci/publish-artifacthub-metadata.sh"
  # A fallback metadata pass must also exclude the private chart.
  rm .ci/published-oci-refs.txt
  bash "$repo_root/.ci/publish-artifacthub-metadata.sh"
  # A release containing only Forgejo refs must not fall back to publishing all charts.
  printf '%s\n' 'git.m0sh1.cc/m0sh1-internal/charts/kded-catalog@sha256:fixture' \
    >.ci/published-oci-refs.txt
  bash "$repo_root/.ci/publish-artifacthub-metadata.sh"
)
grep -Fxq 'push /tmp/kded-catalog.tgz oci://git.m0sh1.cc/m0sh1-internal/charts' "$PUBLISH_TEST_LOG"
grep -Fxq 'push /tmp/demo.tgz oci://ghcr.io/isityael/charts' "$PUBLISH_TEST_LOG"
grep -Fxq 'git.m0sh1.cc/m0sh1-internal/charts/kded-catalog@sha256:fixture' \
  "$tmpdir/.ci/published-oci-refs.txt"
if grep -Eq 'ghcr.io/[^ ]*kded-catalog|kded-catalog:artifacthub.io' "$PUBLISH_TEST_LOG"; then
  echo 'KDED must never publish a chart or Artifact Hub metadata to GHCR' >&2
  exit 1
fi
echo 'KDED Forgejo OCI routing contract passed'
