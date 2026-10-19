#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
helm template basic-memory "${repo_root}/charts/basic-memory" |
  yq -r 'select(.kind == "ConfigMap" and .metadata.name == "basic-memory-mcp-shim") | .data["shim.ts"]' >"${tmpdir}/shim.ts"
deno test --allow-all "${repo_root}/.ci/tests/basic-memory-mcp-shim-sessions.ts" -- "${tmpdir}/shim.ts"
