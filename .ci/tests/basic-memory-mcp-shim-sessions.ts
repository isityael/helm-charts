// Exercise the rendered sidecar against an HTTP MCP server with real session state.
function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}

Deno.test("rendered Basic Memory shim preserves sessions and terminates bounded state", async (t) => {
  const sessions = new Set<string>();
  const deleted: string[] = [];
  const calls: Array<{ sid: string; method: string }> = [];
  let initialized = 0;
  const upstream = Deno.serve(
    { hostname: "127.0.0.1", port: 0, onListen() {} },
    async (req) => {
      const sid = req.headers.get("mcp-session-id") ?? "";
      if (req.method === "DELETE") {
        deleted.push(sid);
        return new Response(null, { status: sessions.delete(sid) ? 204 : 404 });
      }
      const body = req.method === "POST" ? await req.json() : { method: "GET" };
      if (body.method === "initialize") {
        const created = `session-${++initialized}`;
        sessions.add(created);
        return Response.json({ result: {} }, {
          headers: { "mcp-session-id": created },
        });
      }
      calls.push({ sid, method: body.method });
      if (!sessions.has(sid)) {
        return new Response("unknown session", {
          status: 404,
        });
      }
      return Response.json({ result: { sid, tools: [] } });
    },
  );
  const listener = Deno.listen({ hostname: "127.0.0.1", port: 0 });
  const port = (listener.addr as Deno.NetAddr).port;
  listener.close();
  const child = new Deno.Command(Deno.execPath(), {
    args: ["run", "--allow-env", "--allow-net", Deno.args[0]],
    env: {
      MCP_SHIM_LISTEN_PORT: String(port),
      MCP_SHIM_UPSTREAM_PORT: String(upstream.addr.port),
      MCP_SHIM_MAX_SESSIONS: "2",
      MCP_SHIM_ALLOWED_NOTE_DIRS: "projects",
    },
    stdout: "null",
    stderr: "null",
  }).spawn();
  const endpoint = `http://127.0.0.1:${port}/mcp`;
  async function post(
    method: string,
    headers: Record<string, string> = {},
    params: unknown = {},
  ) {
    return await fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json", ...headers },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
    });
  }
  async function init() {
    const response = await post("initialize");
    await response.text();
    return response.headers.get("mcp-session-id")!;
  }
  try {
    for (let attempt = 0;; attempt++) {
      try {
        const r = await fetch(endpoint.replace("/mcp", "/ready"));
        await r.text();
        break;
      } catch (error) {
        if (attempt > 100) throw error;
        await new Promise((r) => setTimeout(r, 20));
      }
    }
    let first = "";
    await t.step("explicit session works without cookies", async () => {
      first = await init();
      const r = await post("tools/list", { "mcp-session-id": first });
      assert(
        (await r.json()).result.sid === first,
        "header session was replaced without cookie",
      );
      assert(initialized === 1, "continuation created another session");
    });
    await t.step(
      "explicit session takes precedence over an unrelated cookie",
      async () => {
        const r = await post("tools/list", {
          "mcp-session-id": first,
          cookie: "mcp_shim_client=unrelated",
        });
        assert(
          (await r.json()).result.sid === first,
          "cookie overrode explicit protocol session",
        );
      },
    );
    await t.step(
      "legacy missing-ID cookie requests reuse one session",
      async () => {
        const a = await post("tools/list", {
          cookie: "mcp_shim_client=legacy",
        });
        const sid = (await a.json()).result.sid;
        const b = await post("tools/list", {
          cookie: "mcp_shim_client=legacy",
        });
        assert(
          (await b.json()).result.sid === sid,
          "legacy cookie session changed",
        );
        assert(
          initialized === 2,
          "legacy continuation created another session",
        );
      },
    );
    await t.step(
      "session continuation preserves blocked-tool and directory policy",
      async () => {
        const before = calls.length;
        for (
          const [name, args, code] of [
            ["create_memory_project", {}, -32006],
            ["delete_project", {}, -32006],
            ["delete_note", {}, -32001],
            ["write_note", { folder: "unapproved" }, -32002],
            ["move_note", { destination_path: "unapproved/note.md" }, -32003],
          ] as const
        ) {
          const r = await post("tools/call", { "mcp-session-id": first }, {
            name,
            arguments: args,
          });
          assert(
            (await r.json()).error.code === code,
            `${name} bypassed policy`,
          );
        }
        assert(
          calls.length === before && initialized === 2,
          "policy rejection reached upstream",
        );
        // Restore legacy session as most recently used for the eviction assertion.
        const r = await post("tools/list", {
          cookie: "mcp_shim_client=legacy",
        });
        await r.text();
      },
    );
    await t.step("DELETE without a session never initializes", async () => {
      const r = await fetch(endpoint, { method: "DELETE" });
      await r.text();
      assert(r.status === 400, "missing DELETE session should return 400");
      assert(initialized === 2, "DELETE created a session");
    });
    await t.step(
      "unknown explicit ID never initializes or executes a mutation",
      async () => {
        const before = calls.length;
        const r = await post("tools/call", {
          "mcp-session-id": "unknown",
          cookie: "mcp_shim_client=legacy",
        });
        await r.text();
        assert(r.status === 404, "unknown explicit session should return 404");
        assert(
          initialized === 2 && calls.length === before,
          "unknown ID executed a call or initialized",
        );
        const initialize = await post("initialize", {
          "mcp-session-id": "unknown",
        });
        await initialize.text();
        assert(
          initialize.status === 404 && initialized === 2,
          "unknown initialize created a session",
        );
      },
    );
    await t.step(
      "LRU eviction terminates upstream and rejects evicted explicit IDs",
      async () => {
        await init();
        assert(deleted.includes(first), "eviction leaked upstream session");
        assert(sessions.size === 2, "upstream session count exceeds bound");
        const r = await post("tools/list", { "mcp-session-id": first });
        await r.text();
        assert(
          r.status === 404 && initialized === 3,
          "evicted ID was silently replaced",
        );
      },
    );
    await t.step(
      "DELETE clears cookie aliases and terminates its existing upstream",
      async () => {
        const r = await fetch(endpoint, {
          method: "DELETE",
          headers: { cookie: "mcp_shim_client=legacy" },
        });
        await r.text();
        assert(
          r.status === 204 && deleted.includes("session-2"),
          "legacy DELETE did not terminate existing session",
        );
        const again = await fetch(endpoint, {
          method: "DELETE",
          headers: { cookie: "mcp_shim_client=legacy" },
        });
        await again.text();
        assert(
          again.status === 400 && initialized === 3,
          "deleted cookie mapping was retained or recreated",
        );
      },
    );
    await t.step(
      "explicit DELETE cleans the protocol session without cookies",
      async () => {
        const r = await fetch(endpoint, {
          method: "DELETE",
          headers: { "mcp-session-id": "session-3" },
        });
        await r.text();
        assert(
          r.status === 204 && deleted.includes("session-3"),
          "explicit DELETE did not reach its upstream session",
        );
        const again = await post("tools/list", {
          "mcp-session-id": "session-3",
        });
        await again.text();
        assert(
          again.status === 404 && initialized === 3,
          "explicit DELETE retained its mapping",
        );
      },
    );
    await t.step(
      "expired upstream session returns 404 without replaying a tool call",
      async () => {
        const sid = await init();
        sessions.delete(sid);
        const before = calls.length;
        const r = await post("tools/call", { "mcp-session-id": sid });
        await r.text();
        assert(
          r.status === 404 && initialized === 4,
          "expired session was reinitialized",
        );
        assert(calls.length === before + 1, "tool call was replayed");
      },
    );
  } finally {
    child.kill("SIGTERM");
    await child.status;
    await upstream.shutdown();
  }
});
