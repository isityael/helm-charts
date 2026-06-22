#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/.ci/pre-commit/helm-lint.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}" /tmp/helm-lint.out' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_repo() {
  local workdir="$1"

  git -C "$workdir" init -q
  git -C "$workdir" config user.email test@example.invalid
  git -C "$workdir" config user.name "Helm Lint Test"

  mkdir -p "$workdir/charts/demo/templates"
  cat >"$workdir/charts/demo/Chart.yaml" <<'YAML'
apiVersion: v2
name: demo
version: 0.1.0
dependencies:
  - name: child
    version: 1.0.0
    repository: https://charts.christianhuth.de
YAML
  cat >"$workdir/charts/demo/templates/configmap.yaml" <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo
YAML

  git -C "$workdir" add charts/demo
  git -C "$workdir" commit -qm "Initial chart"
}

write_fake_helm() {
  local bindir="$1"
  local log="$2"

  cat >"${bindir}/helm" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >> "${log}"

case "\$1" in
  repo)
    case "\$2" in
      list)
        cat <<'OUT'
NAME    URL
repo-0  https://bjw-s-labs.github.io/helm-charts
OUT
        ;;
      add)
        if [ "\$3" = "repo-0" ]; then
          echo "Error: repository name (repo-0) already exists, please specify a different name" >&2
          exit 1
        fi
        ;;
      update)
        ;;
      *)
        echo "unexpected helm repo command: \$*" >&2
        exit 2
        ;;
    esac
    ;;
  dependency)
    [ "\$2" = "build" ] || {
      echo "unexpected helm dependency command: \$*" >&2
      exit 2
    }
    ;;
  lint)
    ;;
  *)
    echo "unexpected helm command: \$*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "${bindir}/helm"
}

test_repo_name_collision_uses_next_available_name() {
  local workdir="${tmpdir}/repo-name-collision"
  local bindir="${workdir}/bin"
  local log="${workdir}/helm.log"
  mkdir -p "$workdir" "$bindir"
  setup_repo "$workdir"
  write_fake_helm "$bindir" "$log"

  printf '\nannotations: {}\n' >>"$workdir/charts/demo/Chart.yaml"
  git -C "$workdir" add charts/demo/Chart.yaml

  (cd "$workdir" && PATH="$bindir:$PATH" "$script") >/tmp/helm-lint.out 2>&1 ||
    fail "expected helm lint hook to avoid existing repo names"

  grep -qx "repo add repo-1 https://charts.christianhuth.de" "$log" ||
    fail "expected hook to add missing repository as repo-1"
}

test_repo_name_collision_uses_next_available_name

echo "helm-lint tests passed"
