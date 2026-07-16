#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart_dir="${repo_root}/charts/basic-memory"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

status=0
notes_template="${chart_dir}/templates/NOTES.txt"

fail() {
  echo "FAIL: $*" >&2
  status=1
}

if rg -q 'obsidianSync\.livesync\.passphrase' "${notes_template}"; then
  fail "NOTES still references the removed inline LiveSync passphrase"
fi
rg -Fq '.Values.obsidianSync.livesync.existingSecret.name' "${notes_template}" \
  || fail "NOTES does not reference the LiveSync existing Secret name"
rg -Fq '.Values.obsidianSync.livesync.existingSecret.passphraseKey' "${notes_template}" \
  || fail "NOTES does not reference the LiveSync passphrase Secret key"

render_livesync() {
  local output="$1"
  shift

  helm template basic-memory "${chart_dir}" \
    --set obsidianSync.enabled=true \
    "$@" >"${output}"
}

unencrypted_render="${tmpdir}/unencrypted.yaml"
if ! render_livesync "${unencrypted_render}"; then
  fail "LiveSync without a passphrase Secret failed to render"
fi

if ! helm template basic-memory "${chart_dir}" \
  -f "${chart_dir}/examples/full-stack.yaml" >"${tmpdir}/full-stack.yaml"; then
  fail "packaged full-stack example failed to render"
fi

secret_render="${tmpdir}/secret-backed.yaml"
if ! render_livesync "${secret_render}" \
  --set obsidianSync.livesync.existingSecret.name=basic-memory-livesync \
  --set obsidianSync.livesync.existingSecret.passphraseKey=passphrase; then
  fail "LiveSync with a passphrase Secret failed to render"
else
  grep -q 'name: LIVESYNC_PASSPHRASE' "${secret_render}" \
    || fail "LiveSync passphrase environment variable is missing"
  grep -q 'name: basic-memory-livesync' "${secret_render}" \
    || fail "LiveSync passphrase Secret name is missing"
  grep -q 'key: passphrase' "${secret_render}" \
    || fail "LiveSync passphrase Secret key is missing"
fi

marker='BASIC_MEMORY_INLINE_PASSPHRASE_MUST_NOT_RENDER'
if render_livesync "${tmpdir}/legacy-inline.yaml" \
  --set-string obsidianSync.livesync.passphrase="${marker}" \
  2>"${tmpdir}/legacy-inline.err"; then
  fail "legacy inline LiveSync passphrase was accepted"
fi
if rg -q "${marker}" "${tmpdir}"; then
  fail "legacy inline LiveSync passphrase marker was rendered"
fi

configmap="${tmpdir}/livesync-configmap.yaml"
yq 'select(.kind == "ConfigMap" and .metadata.name == "basic-memory-livesync-config")' \
  "${secret_render}" >"${configmap}"
grep -q '"passphrase": "__LIVESYNC_PASSPHRASE__"' "${configmap}" \
  || fail "LiveSync ConfigMap passphrase placeholder is missing"
grep -q '"obfuscatePassphrase": "__LIVESYNC_PASSPHRASE__"' "${configmap}" \
  || fail "LiveSync ConfigMap obfuscatePassphrase placeholder is missing"
placeholder_count="$(grep -Ec '"(passphrase|obfuscatePassphrase)": "__LIVESYNC_PASSPHRASE__"' "${configmap}" || true)"
[[ "${placeholder_count}" == "2" ]] || fail "LiveSync ConfigMap does not contain exactly two passphrase placeholders"

grep -q 'const passphrase = Deno.env.get("LIVESYNC_PASSPHRASE") ?? "";' "${secret_render}" \
  || fail "LiveSync config init does not read the optional passphrase environment variable"
grep -q 'peer.passphrase = passphrase;' "${secret_render}" \
  || fail "LiveSync config init does not replace passphrase"
grep -q 'peer.obfuscatePassphrase = passphrase;' "${secret_render}" \
  || fail "LiveSync config init does not replace obfuscatePassphrase"
grep -q 'peer.password = pw;' "${secret_render}" \
  || fail "LiveSync config init no longer replaces the CouchDB password"

if ((status != 0)); then
  exit "${status}"
fi

echo "Basic Memory LiveSync Secret contract passed"
