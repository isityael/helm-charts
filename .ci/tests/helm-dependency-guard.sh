#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/.ci/check-helm-dependencies.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}" /tmp/helm-dependency-guard.out' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_repo() {
  local workdir="$1"
  local chart="$2"
  local repository="${3:-https://example.invalid/charts}"

  git -C "$workdir" init -q
  git -C "$workdir" config user.email test@example.invalid
  git -C "$workdir" config user.name "Helm Dependency Guard Test"

  mkdir -p "$workdir/charts/${chart}/charts"
  cat >"$workdir/charts/${chart}/Chart.yaml" <<YAML
apiVersion: v2
name: ${chart}
version: 0.1.0
dependencies:
  - name: child
    version: 1.0.0
    repository: ${repository}
YAML
  cat >"$workdir/charts/${chart}/Chart.lock" <<'YAML'
dependencies:
- name: child
  repository: https://example.invalid/charts
  version: 1.0.0
digest: sha256:test
generated: "2026-01-01T00:00:00Z"
YAML
  touch "$workdir/charts/${chart}/charts/child-1.0.0.tgz"
  git -C "$workdir" add charts
  git -C "$workdir" commit -qm "Initial chart"
}

write_fake_helm() {
  local bindir="$1"
  local status="$2"
  local mutate="${3:-false}"

  cat >"${bindir}/helm" <<SH
#!/usr/bin/env bash
set -euo pipefail
case "\$1 \$2" in
  "dependency list")
    cat <<'OUT'
NAME  VERSION  REPOSITORY                    STATUS
child 1.0.0    https://example.invalid/charts ${status}
OUT
    ;;
  "dependency build")
    if [ "${mutate}" = "true" ]; then
      echo "changed by build" >> "\$3/Chart.lock"
    fi
    ;;
  *)
    echo "unexpected helm command: \$*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "${bindir}/helm"
}

write_missing_git() {
  local bindir="$1"

  cat >"${bindir}/git" <<'SH'
#!/usr/bin/env bash
echo "git: command not found" >&2
exit 127
SH
  chmod +x "${bindir}/git"
}

write_failing_dependency_build_helm() {
  local bindir="$1"

  cat >"${bindir}/helm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
  "dependency list")
    cat <<'OUT'
NAME  VERSION  REPOSITORY     STATUS
child 1.0.0    oci://dhi.io   ok
OUT
    ;;
  "dependency build")
    echo "dependency build should have been skipped" >&2
    exit 1
    ;;
  *)
    echo "unexpected helm command: $*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "${bindir}/helm"
}

test_fails_on_wrong_dependency_status() {
  local workdir="${tmpdir}/wrong-status"
  local bindir="${workdir}/bin"
  mkdir -p "$workdir" "$bindir"
  setup_repo "$workdir" demo
  write_fake_helm "$bindir" "wrong version"

  if (cd "$workdir" && PATH="$bindir:$PATH" "$script") >/tmp/helm-dependency-guard.out 2>&1; then
    fail "expected wrong dependency status to fail"
  fi

  grep -q "wrong version" /tmp/helm-dependency-guard.out ||
    fail "expected output to mention wrong version"
}

test_fails_when_build_mutates_vendored_files() {
  local workdir="${tmpdir}/mutated"
  local bindir="${workdir}/bin"
  mkdir -p "$workdir" "$bindir"
  setup_repo "$workdir" demo
  write_fake_helm "$bindir" "ok" "true"

  if (cd "$workdir" && PATH="$bindir:$PATH" "$script") >/tmp/helm-dependency-guard.out 2>&1; then
    fail "expected dependency build mutation to fail"
  fi

  grep -q "changed during dependency build" /tmp/helm-dependency-guard.out ||
    fail "expected output to mention dependency build drift"
}

test_passes_when_dependencies_are_current() {
  local workdir="${tmpdir}/ok"
  local bindir="${workdir}/bin"
  mkdir -p "$workdir" "$bindir"
  setup_repo "$workdir" demo
  write_fake_helm "$bindir" "ok"

  (cd "$workdir" && PATH="$bindir:$PATH" "$script") >/tmp/helm-dependency-guard.out 2>&1 ||
    fail "expected current dependencies to pass"
}

test_passes_without_git_available() {
  local workdir="${tmpdir}/no-git"
  local bindir="${workdir}/bin"
  mkdir -p "$workdir" "$bindir"
  setup_repo "$workdir" demo
  write_fake_helm "$bindir" "ok"
  write_missing_git "$bindir"

  (cd "$workdir" && PATH="$bindir:$PATH" "$script") >/tmp/helm-dependency-guard.out 2>&1 ||
    fail "expected current dependencies to pass without git"
}

test_skips_dhi_build_without_credentials() {
  local workdir="${tmpdir}/dhi-no-creds"
  local bindir="${workdir}/bin"
  mkdir -p "$workdir" "$bindir"
  setup_repo "$workdir" demo "oci://dhi.io"
  write_failing_dependency_build_helm "$bindir"

  (cd "$workdir" && PATH="$bindir:$PATH" "$script") >/tmp/helm-dependency-guard.out 2>&1 ||
    fail "expected DHI dependency build to be skipped without credentials"

  grep -q "Skipping dependency build for charts/demo" /tmp/helm-dependency-guard.out ||
    fail "expected output to mention skipped DHI dependency build"
}

test_fails_on_wrong_dependency_status
test_fails_when_build_mutates_vendored_files
test_passes_when_dependencies_are_current
test_passes_without_git_available
test_skips_dhi_build_without_credentials

echo "helm-dependency-guard tests passed"
