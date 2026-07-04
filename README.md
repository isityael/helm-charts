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

| Chart | Version | Description |
|-------|---------|-------------|
| `basic-memory` | 0.3.22 | Basic Memory MCP server with optional Obsidian LiveSync integration |
| `cloudflared` | 1.4.9 | Cloudflare Tunnel connector |
| `cnpg-stack` | 0.13.37 | CloudNativePG operator, cluster, barman plugin, pooler, and metrics wrapper |
| `csi-driver-nfs` | 4.14.4 | NFS CSI driver (isityael fork with configurable fsGroupPolicy) |
| `fail2ban-gotify-relay` | 0.3.3 | Relay fail2ban-ui webhook events to Gotify |
| `forgejo` | 0.1.11 | Forgejo with custom image defaults and optional runner |
| `forgejo-runner` | 0.1.9 | Forgejo Actions runner with Docker-in-Docker |
| `gitea-runner` | 1.0.6 | Gitea Actions runner with Docker-in-Docker |
| `m0sh1-exporter` | 0.1.17 | Network exporters bundle for OPNsense, SNMP, and Proxmox VE |
| `matrix-umbrella` | 0.1.25 | DHI-first Matrix Synapse, MAS, Element Web, Cinny, and bridge umbrella |
| `privatebin` | 0.1.3 | Encrypted paste and file sharing |
| `proxmox-csi-plugin` | 0.5.40 | Proxmox CSI plugin (isityael fork) |
| `searxng` | 0.2.8 | Privacy-respecting metasearch |
| `tailscale-webhook-relay` | 0.3.3 | Relay Tailscale webhook events to ntfy |
| `traefik` | 0.1.0 | Traefik wrapper based on Docker Hardened Images with m0sh1 edge defaults |
| `umami` | 0.2.4 | Privacy-focused web analytics |
| `wakapi-dhi` | 1.2.19 | Hardened WakaTime-compatible coding statistics |
| `youtarr` | 0.1.0 | YouTube downloader with DHI MariaDB support |

## Publishing

Charts are automatically published to GHCR OCI on push to `main` when `charts/**` files change (via Woodpecker CI). Manual trigger is also supported.

Tag-triggered releases (e.g. `cloudflared-v*`, `csi-driver-nfs-v*`) additionally create GitHub Releases with packaged `.tgz` artefacts.

The publish script records pushed immutable OCI digest references in `.ci/published-oci-refs.txt`. If `COSIGN_PRIVATE_KEY` and `COSIGN_PASSWORD` are present in the script environment, those digest references are signed with `cosign sign --key env://COSIGN_PRIVATE_KEY`.

## Development

```bash
# Lint a chart
helm lint charts/<chart-name>

# Lint all charts
mise run helm-lint

# Verify vendored chart dependencies
.ci/check-helm-dependencies.sh

# Lint rendered manifests after generating .ci/rendered
mise run kube-linter
```

## Licence

See `LICENSE`.
