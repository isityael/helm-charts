#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart_dir="${repo_root}/charts/basic-memory"
tmpdir="$(mktemp -d)"
shim_pid=""
upstream_pid=""

cleanup() {
  if [ -n "${shim_pid}" ]; then
    kill "${shim_pid}" 2>/dev/null || true
    wait "${shim_pid}" 2>/dev/null || true
  fi
  if [ -n "${upstream_pid}" ]; then
    kill "${upstream_pid}" 2>/dev/null || true
    wait "${upstream_pid}" 2>/dev/null || true
  fi
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

default_rendered="${tmpdir}/default-rendered.yaml"
helm template basic-memory "${chart_dir}" >"${default_rendered}"
default_containers="$(
  yq -r '
    select(.kind == "Deployment") |
    .spec.template.spec.containers[].name
  ' "${default_rendered}"
)"
grep -qx 'mcp-shim' <<<"${default_containers}" ||
  fail "mcpShim must be enabled by default"

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
          { name: "read_note" },
          { name: "write_note" },
          { name: "move_note" },
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
for allowed_tool in read_note write_note move_note; do
  grep -qx "${allowed_tool}" <<<"${tool_names}" ||
    fail "tools/list must retain ${allowed_tool}"
done
if grep -Eq '^(create_memory_project|delete_project)$' <<<"${tool_names}"; then
  fail "tools/list must hide blocked project-management tools"
fi

request_id=2
for blocked_tool in create_memory_project delete_project; do
  blocked_call="$(curl --silent --show-error --fail \
    --header 'content-type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":${request_id},\"method\":\"tools/call\",\"params\":{\"name\":\"${blocked_tool}\",\"arguments\":{}}}" \
    http://127.0.0.1:18000/mcp)"
  [ "$(yq -r '.error.code' <<<"${blocked_call}")" = "-32006" ] ||
    fail "tools/call must reject ${blocked_tool}"
  request_id=$((request_id + 1))
done

for allowed_tool in read_note write_note move_note; do
  case "${allowed_tool}" in
    write_note)
      allowed_args='{"folder":"ci-test"}'
      ;;
    move_note)
      allowed_args='{"destination_path":"ci-test/moved-note.md"}'
      ;;
    *)
      allowed_args='{}'
      ;;
  esac
  allowed_call="$(curl --silent --show-error --fail \
    --header 'content-type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":${request_id},\"method\":\"tools/call\",\"params\":{\"name\":\"${allowed_tool}\",\"arguments\":${allowed_args}}}" \
    http://127.0.0.1:18000/mcp)"
  [ "$(yq -r '.result.forwarded' <<<"${allowed_call}")" = "true" ] ||
    fail "tools/call must preserve ${allowed_tool}"
  request_id=$((request_id + 1))
done

echo "basic-memory MCP shim policy tests passed"
