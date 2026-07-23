# basic-memory

A Helm chart for [Basic Memory](https://github.com/basicmachines-co/basic-memory) — a local-first knowledge graph MCP server that lets LLMs like Claude create, read and update Markdown notes through the Model Context Protocol.

This chart ships the upstream Basic Memory server with two **optional** sidecar profiles for power users:

- **MCP shim** — a small Deno reverse proxy that normalises non-compliant JSON-RPC from buggy MCP clients, injects a default project argument, enforces a write-directory allowlist, and throttles mutating tool calls.
- **Obsidian LiveSync** — a CouchDB + [`livesync-bridge`](https://github.com/isityael/livesync-bridge) sidecar pair that bidirectionally syncs the Basic Memory notes directory with an Obsidian vault via the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin.

Both profiles are **disabled by default**. A plain `helm install` gives you a single clean Basic Memory pod and nothing else.

## TL;DR

This chart is published as an **OCI artifact** on GitHub Container Registry. Helm 3.8+ can install directly from OCI — no `helm repo add` needed:

```bash
helm install basic-memory oci://ghcr.io/isityael/charts/basic-memory
```

Or pin a specific version:

```bash
helm install basic-memory oci://ghcr.io/isityael/charts/basic-memory --version 0.3.7
```

See [all available versions](https://github.com/isityael/helm-charts/pkgs/container/charts%2Fbasic-memory) on GHCR.

## Prerequisites

- Kubernetes 1.28+
- A default `StorageClass` (or set `persistence.storageClass` and `basicMemoryHome.storageClass`)
- An ingress controller if you want external access

## Quick starts

### Core only (most users)

```yaml
# values.yaml
persistence:
  enabled: true
  size: 10Gi

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: basic-memory.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - basic-memory.example.com
      secretName: basic-memory-tls
```

```bash
helm install basic-memory oci://ghcr.io/isityael/charts/basic-memory -f values.yaml
```

Your MCP client (Claude Desktop, Cursor, Continue, etc.) connects to `https://basic-memory.example.com/mcp`.

If your cluster uses Gateway API, configure `httpRoute` instead of `ingress`:

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: traefik-gateway
      namespace: traefik
      sectionName: websecure
  hostnames:
    - basic-memory.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
```

### With the MCP shim (buggy clients or strict policy)

Enable the shim if your client doesn't always emit a valid `jsonrpc: "2.0"` header, or if you want to constrain where the LLM can write notes.

```yaml
mcpShim:
  enabled: true
  policy:
    allowedNoteDirs:
      - inbox
      - journal
      - decisions
    allowDeleteNote: false     # never let the LLM delete notes
  maxToolCallConcurrency: 4    # at most 4 concurrent write_note/edit_note
```

### With Obsidian LiveSync

First, create the CouchDB credentials Secret:

```bash
kubectl create secret generic basic-memory-couchdb \
  --from-literal=COUCHDB_USER=admin \
  --from-literal=COUCHDB_PASSWORD="$(openssl rand -base64 24)"
```

Then enable the profile:

```yaml
obsidianSync:
  enabled: true
  livesync:
    database: obsidian-vault
    passphrase: "change-me-to-match-your-obsidian-plugin"
  couchdb:
    persistence:
      size: 5Gi
    ingress:
      enabled: true
      className: nginx
      host: livesync.example.com
      tls:
        - hosts:
            - livesync.example.com
          secretName: livesync-tls
```

Point the Self-hosted LiveSync plugin in Obsidian at `https://livesync.example.com`, database `obsidian-vault`, and the same passphrase.

If your cluster uses Gateway API for the CouchDB endpoint, disable `obsidianSync.couchdb.ingress`
and configure `obsidianSync.couchdb.httpRoute` instead:

```yaml
obsidianSync:
  enabled: true
  couchdb:
    ingress:
      enabled: false
      host: livesync.example.com
    httpRoute:
      enabled: true
      parentRefs:
        - group: gateway.networking.k8s.io
          kind: Gateway
          name: traefik-gateway
          namespace: traefik
          sectionName: websecure
      hostnames:
        - livesync.example.com
```

### Both profiles together

All three components play nicely:

```
                         ┌────────────────────┐
 MCP client ──/mcp──▶    │    mcp-shim        │ ──▶ 127.0.0.1:8001 (basic-memory)
                         └────────────────────┘
                                                          │
                                                          ▼
                                                 /app/data/basic-memory
                                                          ▲
                                                          │
            ┌───────────────┐                  ┌──────────────────────┐
 Obsidian ─▶│  couchdb      │ ◀────────────── │  livesync-bridge     │
            └───────────────┘                  └──────────────────────┘
```

## Configuration

See [`values.yaml`](./values.yaml) for the full list. Highlights:

| Key | Default | Description |
|---|---|---|
| `image.repository` | `ghcr.io/basicmachines-co/basic-memory` | Upstream Basic Memory image |
| `image.tag` | `""` (uses chart appVersion) | Override tag |
| `denoTools.image.repository` | `dhi.io/deno` | Deno utility image for chart-owned helper scripts |
| `livesyncBridge.image.repository` | `ghcr.io/isityael/livesync-bridge` | Node runtime image for the LiveSync sync daemon |
| `livesyncBridge.image.tag` | *(pinned SHA)* | See *Image inheritance* below |
| `persistence.enabled` | `true` | PVC for notes + model cache |
| `persistence.size` | `5Gi` | Scale this to your vault size |
| `service.port` | `8000` | ClusterIP port |
| `service.ipFamilyPolicy` | `SingleStack` | See *Gotchas* below |
| `mcpShim.enabled` | `false` | Enable the MCP compatibility shim |
| `mcpShim.image` | `{}` *(inherits)* | Optional override on top of `denoTools.image` |
| `mcpShim.policy.allowedNoteDirs` | `[]` | Empty = allow all; list to restrict |
| `mcpShim.policy.allowDeleteNote` | `false` | Set `true` to let LLMs delete notes |
| `obsidianSync.enabled` | `false` | Enable CouchDB + livesync-bridge |
| `obsidianSync.livesync.image` | `{}` *(inherits)* | Optional override on top of `livesyncBridge.image` |
| `obsidianSync.livesync.configInitImage` | `{}` *(inherits)* | Optional override on top of `denoTools.image` |
| `obsidianSync.couchdb.existingSecret.name` | `basic-memory-couchdb` | Pre-created CouchDB credentials |
| `obsidianSync.couchdb.cors.enabled` | `false` | Enable browser CORS; prefer Obsidian's Request API |
| `obsidianSync.couchdb.cors.origins` | `[]` | Exact allowed browser origins; required when CORS is enabled |
| `obsidianSync.couchdb.cors.credentials` | `false` | Permit credentialed CORS; wildcard origins are rejected |
| `obsidianSync.couchdb.httpRoute.enabled` | `false` | Gateway API HTTPRoute exposure for the CouchDB endpoint |
| `ingress.enabled` | `false` | Standard Helm ingress block |
| `httpRoute.enabled` | `false` | Gateway API HTTPRoute exposure (mutually exclusive with `ingress.enabled`) |

### Image inheritance

The chart separates runtime images by job:

- `livesyncBridge.image` is the Node-based LiveSync sync daemon.
- `denoTools.image` is the Deno runtime for chart-owned helper scripts: the MCP shim sidecar and LiveSync config-init container.

To override the LiveSync daemon tag, set `livesyncBridge.image.tag`:

```yaml
livesyncBridge:
  image:
    tag: "my-custom-sha"
```

To override only one helper consumer, set the relevant subblock — any field you specify is merged on top of the matching root image, so you only need to state what changes:

```yaml
# Example: use a different tag for the MCP shim sidecar only
mcpShim:
  enabled: true
  image:
    tag: "alternative-tag"      # denoTools repository + pullPolicy inherited
```

This keeps LiveSync daemon updates from accidentally replacing Deno-only helper containers with a Node-only runtime image.

## Gotchas

### `HF_HUB_OFFLINE=1` is not optional

The chart ships `HF_HUB_OFFLINE=1` as a default env var and runs a dedicated `semantic-model-cache-init` initContainer to warm the fastembed ONNX model into the PVC once. **Do not disable this.**

Without `HF_HUB_OFFLINE=1`, fastembed re-validates the model against Hugging Face on every pod restart. The unauthenticated Hugging Face download silently drops files during network blips, which corrupts the cache and breaks semantic search until you manually wipe and re-download. This is a real problem, not paranoia — the init-container + offline mode dance is the fix.

### IPv4-only Service by default

The upstream Basic Memory Python server binds `0.0.0.0` on IPv4 only. If you run a dual-stack cluster and the Service picks an IPv6 endpoint, some ingress controllers (notably Traefik) return HTTP 502 on every request. The chart defaults to `service.ipFamilyPolicy: SingleStack` + `service.ipFamilies: [IPv4]` to avoid this. Only change it if you've tested IPv6 reachability end-to-end.

### Single replica only

Basic Memory stores notes on a RWO PVC. `replicaCount: 1` and `strategy.type: Recreate` are the only sensible defaults. Don't scale this horizontally — the graph database and watcher state aren't clustered.

### `mcpShim.policy.allowedNoteDirs` is empty by default

An empty allowlist means **allow all directories**. If you set it to `["inbox", "journal"]`, the LLM can only `write_note` into top-level `inbox/…` or `journal/…`. This is deliberately opt-in: most users want unrestricted writes.

### Obsidian LiveSync requires a pre-created Secret

The chart does not create the CouchDB credentials Secret for you (we don't want to touch plaintext passwords in chart values). Create it with `kubectl create secret generic basic-memory-couchdb --from-literal=...` before `helm install`, or use a SealedSecret / SOPS equivalent.

## Examples

See [`examples/`](./examples/) for full values files covering:

- `gateway-api.yaml` — exposing Basic Memory with Gateway API HTTPRoute
- `traefik-forward-auth.yaml` — protecting the ingress with Authentik/Authelia forward-auth
- `full-stack.yaml` — all three components enabled

## Credits

- Upstream Basic Memory by [basicmachines-co](https://github.com/basicmachines-co/basic-memory) (AGPL-3.0)
- MCP shim + LiveSync bridge by [@isityael](https://github.com/isityael)
- Chart by [@isityael](https://github.com/isityael)
