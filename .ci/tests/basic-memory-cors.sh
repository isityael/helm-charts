#!/usr/bin/env bash
set -euo pipefail

chart_dir="charts/basic-memory"
release_name="basic-memory-cors-test"
namespace="basic-memory"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

render_chart() {
  helm template "${release_name}" "${chart_dir}" \
    --namespace "${namespace}" \
    --set obsidianSync.enabled=true \
    --set obsidianSync.couchdb.existingSecret.name=basic-memory-couchdb \
    --set obsidianSync.livesync.existingSecret.name=basic-memory-livesync \
    "$@"
}

test_cors_is_disabled_by_default() {
  local rendered="${tmp_dir}/default.yaml"

  render_chart >"${rendered}"

  grep -F 'enable_cors = false' "${rendered}" >/dev/null || {
    echo "expected CouchDB CORS to be disabled by default" >&2
    return 1
  }

  if grep -F 'origins = *' "${rendered}" >/dev/null; then
    echo "wildcard CouchDB CORS must not be rendered by default" >&2
    return 1
  fi
}

test_explicit_origin_allowlist_is_rendered() {
  local rendered="${tmp_dir}/allowlist.yaml"

  render_chart \
    --set obsidianSync.couchdb.cors.enabled=true \
    --set 'obsidianSync.couchdb.cors.origins[0]=app://obsidian.md' \
    --set 'obsidianSync.couchdb.cors.origins[1]=capacitor://localhost' \
    >"${rendered}"

  grep -F 'enable_cors = true' "${rendered}" >/dev/null
  grep -F 'origins = app://obsidian.md, capacitor://localhost' "${rendered}" >/dev/null
  grep -F 'credentials = false' "${rendered}" >/dev/null
}

test_wildcard_with_credentials_is_rejected() {
  local stderr="${tmp_dir}/wildcard-credentials.stderr"

  if render_chart \
    --set obsidianSync.couchdb.cors.enabled=true \
    --set 'obsidianSync.couchdb.cors.origins[0]=*' \
    --set obsidianSync.couchdb.cors.credentials=true \
    >/dev/null 2>"${stderr}"; then
    echo "expected wildcard credentialed CORS values to fail rendering" >&2
    return 1
  fi

  grep -F 'cannot use wildcard origins with credentials' "${stderr}" >/dev/null
}

test_cors_is_disabled_by_default
test_explicit_origin_allowlist_is_rendered
test_wildcard_with_credentials_is_rejected

echo "basic-memory CORS tests passed"
