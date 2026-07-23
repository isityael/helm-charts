#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart_dir="${repo_root}/charts/basic-memory"
tmpdir="$(mktemp -d)"
shim_pid=""
upstream_pid=""

cleanup() {
  [ -z "${shim_pid}" ] || kill "${shim_pid}" 2>/dev/null || true
  [ -z "${upstream_pid}" ] || kill "${upstream_pid}" 2>/dev/null || true
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

rendered="${tmpdir}/rendered.yaml"
helm template basic-memory "${chart_dir}" -f "${chart_dir}/ci/test-values.yaml" >"${rendered}"
yq -r 'select(.kind == "ConfigMap" and .metadata.name == "basic-memory-mcp-shim") | .data["shim.ts"]' \
  "${rendered}" >"${tmpdir}/shim.ts"

blocked_tools="$(
  yq -r '
    select(.kind == "Deployment") |
    .spec.template.spec.containers[] |
    select(.name == "mcp-shim") |
    .env[] |
    select(.name == "MCP_SHIM_BLOCKED_TOOLS") |
    .value
  ' "${rendered}"
)"
[ "${blocked_tools}" = "create_memory_project,delete_project" ] ||
  fail "mcpShim must pass the default blocked tools policy to the sidecar"

deno eval '
  Deno.serve({ hostname: "127.0.0.1", port: 18001 }, async (request) => {
    const body = await request.json();
    if (body.method === "initialize") {
      return new Response(JSON.stringify({ jsonrpc: "2.0", id: body.id, result: {} }), {
        headers: { "content-type": "application/json", "mcp-session-id": "test-session" },
      });
    }
    if (body.method === "tools/list") {
      return Response.json({
        jsonrpc: "2.0",
        id: body.id,
        result: { tools: [
          { name: "create_memory_project" },
          { name: "delete_project" },
          { name: "write_note" },
        ] },
      });
    }
    return Response.json({ jsonrpc: "2.0", id: body.id, result: { forwarded: true } });
  });
  await new Promise(() => {});
' >/dev/null 2>&1 &
upstream_pid="$!"

MCP_SHIM_LISTEN_PORT=18000 \
MCP_SHIM_UPSTREAM_PORT=18001 \
MCP_SHIM_BLOCKED_TOOLS="${blocked_tools}" \
deno run --allow-env --allow-net "${tmpdir}/shim.ts" >"${tmpdir}/shim.log" 2>&1 &
shim_pid="$!"

for _ in $(seq 1 50); do
  if curl --silent --fail http://127.0.0.1:18000/mcp >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

tools_list="$(curl --silent --show-error --fail \
  --header 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  http://127.0.0.1:18000/mcp)"

tool_names="$(yq -r '.result.tools[].name' <<<"${tools_list}")"
grep -qx 'write_note' <<<"${tool_names}" || fail "tools/list must retain allowed tools"
if grep -Eq '^(create_memory_project|delete_project)$' <<<"${tool_names}"; then
  fail "tools/list must hide blocked project-management tools"
fi

blocked_call="$(curl --silent --show-error --fail \
  --header 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"delete_project","arguments":{}}}' \
  http://127.0.0.1:18000/mcp)"
[ "$(yq -r '.error.code' <<<"${blocked_call}")" = "-32006" ] ||
  fail "tools/call must reject blocked project-management tools"

allowed_call="$(curl --silent --show-error --fail \
  --header 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"write_note","arguments":{"folder":"ci-test"}}}' \
  http://127.0.0.1:18000/mcp)"
[ "$(yq -r '.result.forwarded' <<<"${allowed_call}")" = "true" ] ||
  fail "tools/call must preserve allowed note writes"

echo "basic-memory MCP shim policy tests passed"
