# Helm Charts

Helm charts published as OCI artefacts to `oci://ghcr.io/yaelmoshi/charts`.

## Usage

```bash
# Pull a chart
helm pull oci://ghcr.io/yaelmoshi/charts/<chart-name> --version <version>

# Install directly from OCI
helm install <release-name> oci://ghcr.io/yaelmoshi/charts/<chart-name> --version <version>
```

## Charts

| Chart | Version | Description |
|-------|---------|-------------|
| `cloudflared` | 1.1.0 | Cloudflare Tunnel connector |
| `csi-driver-nfs` | 4.14.1 | NFS CSI driver (yaelmoshi fork with configurable fsGroupPolicy) |
| `forgejo` | 0.1.5 | Forgejo with custom image defaults and optional runner |
| `forgejo-runner` | 0.1.5 | Forgejo Actions runner with Docker-in-Docker |
| `gitea-runner` | 0.4.0 | Gitea Actions runner with Docker-in-Docker |
| `healthchecks` | 0.1.0 | Cron and background task monitoring |
| `m0sh1-exporter` | 0.1.0 | Network exporters bundle for OPNsense, SNMP, and Proxmox VE |
| `privatebin` | 0.1.0 | Encrypted paste and file sharing |
| `searxng` | 0.1.0 | Privacy-respecting metasearch |
| `tailscale-webhook-relay` | 0.1.0 | Relay Tailscale webhook events to ntfy |
| `wakapi` | 1.2.1 | Hardened WakaTime-compatible coding statistics |

## Publishing

Charts are automatically published to GHCR OCI on push to `main` when `charts/**` files change (via Woodpecker CI). Manual trigger is also supported.

Tag-triggered releases (e.g. `cloudflared-v*`, `csi-driver-nfs-v*`) additionally create GitHub Releases with packaged `.tgz` artefacts.

## Development

```bash
# Lint a chart
helm lint charts/<chart-name>

# Lint all charts
for chart in charts/*/; do helm lint "$chart"; done
```

## Licence

See `LICENSE`.
