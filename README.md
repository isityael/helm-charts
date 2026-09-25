# Helm Charts

Helm charts published as OCI artefacts to `oci://ghcr.io/isityael/charts`.

## Usage

```bash
# Pull a chart
helm pull oci://ghcr.io/isityael/charts/<chart-name> --version <version>

# Install directly from OCI
helm install <release-name> oci://ghcr.io/isityael/charts/<chart-name> --version <version>
```

## Charts

| Chart | Description |
| --- | --- |
| `basic-memory` | Basic Memory MCP server with an optional Obsidian LiveSync integration |
| `cloudflared` | Cloudflare Tunnel connector |
| `cnpg-stack` | CloudNativePG operator, cluster, Barman Cloud plugin, PgBouncer pooler and scrape objects |
| `csi-driver-nfs` | NFS CSI driver (isityael fork with configurable fsGroupPolicy) |
| `csi-s3` | k8s-csi-s3 with an owned driver image and multiple StorageClasses |
| `forgejo` | Forgejo with custom image defaults and an optional runner |
| `forgejo-runner` | Forgejo Actions runner with optional Docker-in-Docker |
| `m0sh1-exporter` | Network exporters for OPNsense, SNMP and Proxmox VE |
| `proxmox-csi-plugin` | Proxmox CSI plugin (isityael fork) |
| `tailscale-webhook-relay` | Relays Tailscale webhook events to ntfy |
| `traefik` | Traefik on Docker Hardened Images with m0sh1 edge defaults |
| `wakapi-dhi` | Wakapi, the WakaTime-compatible coding statistics server, on Docker Hardened Images |

Current versions are in each `charts/<chart>/Chart.yaml` and on
[GHCR](https://github.com/isityael?tab=packages).
Retired charts are kept outside Git in `charts/deprecated/` (ignored).

## Publishing

On every push to `main` that touches `charts/**`, Woodpecker's `release-all`
pipeline publishes each chart version that isn't on GHCR yet. It runs only
after the `build` pipeline passes, and it can also be triggered manually.

Forgejo Actions (`.forgejo/workflows/release-tag.yaml`) then tags each
published version as `<chart>-v<version>`. It first waits for both Woodpecker
pipelines to succeed on that commit.

The publish script records pushed immutable OCI digest references in `.ci/published-oci-refs.txt`. If `COSIGN_PRIVATE_KEY` and `COSIGN_PASSWORD` are present in the script environment, those digest references are signed with `cosign sign --key env://COSIGN_PRIVATE_KEY`.

### Artifact Hub OCI metadata

The release pipeline also publishes repository metadata to the `artifacthub.io`
tag of every active chart repository. The OCI payload contains the owners from
`artifacthub-repo.yml`, but deliberately omits its `repositoryID`: that ID
belongs to the legacy HTTP chart repository and is not valid for OCI charts.

Artifact Hub requires one repository registration per OCI chart. Register each
chart in the Artifact Hub control panel with a URL in this form:

```text
oci://ghcr.io/isityael/charts/<chart-name>
```

Each registration receives a unique repository ID. Add per-chart IDs only if
Verified Publisher status is needed; never reuse the legacy HTTP repository ID.

## Development

```bash
# Install the prek hooks (YAML checks, chart version bump, Helm lint)
mise run hooks-install

# Lint and render all charts, or only the ones given
mise run helm-lint
mise run helm-lint charts/<chart-name>

# Validate the rendered manifests in .ci/rendered
mise run kube-linter

# Run the repository contract tests
mise run test-shell
```

## Licence

See `LICENSE`.
