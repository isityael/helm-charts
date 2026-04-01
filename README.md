# Helm Charts

Helm charts published as OCI artefacts to `oci://ghcr.io/sm-moshi/charts`.

## Usage

```bash
# Pull a chart
helm pull oci://ghcr.io/sm-moshi/charts/<chart-name> --version <version>

# Install directly from OCI
helm install <release-name> oci://ghcr.io/sm-moshi/charts/<chart-name> --version <version>
```

## Charts

| Chart | Version | Description |
|-------|---------|-------------|
| `argus` | 0.7.0 | Release monitoring (Release-Argus) |
| `cloudflared` | 1.1.0 | Cloudflare Tunnel connector |
| `csi-driver-nfs` | 4.14.0 | NFS CSI driver (sm-moshi fork with configurable fsGroupPolicy) |
| `cyberchef` | 0.4.0 | CyberChef data utilities |
| `gitea-runner` | 0.4.0 | Gitea Actions runner with Docker-in-Docker |
| `homepage` | 0.5.0 | Homepage dashboard |
| `it-tools` | 0.4.0 | IT utilities dashboard |
| `tailscale-webhook-relay` | 0.1.0 | Relay Tailscale webhook events to ntfy |
| `wakapi` | 1.1.0 | WakaTime-compatible coding statistics |
| `wud` | 0.4.0 | What's Up Docker — update monitor |

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
