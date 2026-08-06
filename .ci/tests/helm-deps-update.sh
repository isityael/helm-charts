#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${repo_root}/.ci/helm-deps-update.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q '^\[tasks\."helm:deps-update"\]$' "${repo_root}/mise.toml" ||
  fail "expected mise run helm:deps-update task"
grep -A3 '^\[tasks\.helm-deps-update\]$' "${repo_root}/mise.toml" |
  grep -q 'depends.*"helm:deps-update"' ||
  fail "expected helm-deps-update compatibility alias"
grep -q '^task\.run_auto_install[[:space:]]*=[[:space:]]*true$' "${repo_root}/mise.toml" ||
  fail "expected supported mise task.run_auto_install setting"
if grep -q '^task_run_auto_install[[:space:]]*=' "${repo_root}/mise.toml"; then
  fail "deprecated mise task_run_auto_install setting remains"
fi

mkdir -p "${tmpdir}/bin"

mkdir -p "${tmpdir}/charts/no-dependencies"
cat >"${tmpdir}/charts/no-dependencies/Chart.yaml" <<'YAML'
apiVersion: v2
name: no-dependencies
version: 0.1.0
YAML

for chart in current stale; do
  mkdir -p "${tmpdir}/charts/${chart}/charts"
  cat >"${tmpdir}/charts/${chart}/Chart.yaml" <<YAML
apiVersion: v2
name: ${chart}
version: 0.1.0
dependencies:
  - name: child
    version: 1.2.3
    repository: https://example.invalid/charts
YAML
  touch "${tmpdir}/charts/${chart}/Chart.lock"
done
touch "${tmpdir}/charts/current/charts/child-1.2.3.tgz"

cat >"${tmpdir}/bin/helm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

case "$1 $2" in
  "dependency list")
    cat <<'OUT'
NAME  VERSION  REPOSITORY                      STATUS
child 1.2.3    https://example.invalid/charts  ok
OUT
    ;;
  "dependency update")
    printf '%s\n' "$3" >>"${HELM_UPDATE_LOG}"
    touch "${3%/}/charts/child-1.2.3.tgz"
    ;;
  *)
    echo "unexpected helm command: $*" >&2
    exit 2
    ;;
esac
SH
chmod +x "${tmpdir}/bin/helm"

output="$({
  cd "${tmpdir}"
  HELM_CHARTS_ROOT="${tmpdir}" HELM_UPDATE_LOG="${tmpdir}/updates.log" PATH="${tmpdir}/bin:${PATH}" "${script}"
})"

[ "$(cat "${tmpdir}/updates.log")" = "charts/stale/" ] ||
  fail "expected only charts/stale/ to be updated"
printf '%s\n' "${output}" | grep -q '^  dep update: charts/stale/$' ||
  fail "expected stale chart update output"
printf '%s\n' "${output}" | grep -q '^  done: 1 built, 2 skipped (up-to-date)$' ||
  fail "expected concise built/skipped summary"

echo "helm-deps-update tests passed"
