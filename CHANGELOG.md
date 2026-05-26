## [unreleased]

### 🚀 Features

- Feat: add fail2ban-gotify-relay chart

Helm chart for the fail2ban-gotify-relay webhook translator.
Converts fail2ban-ui webhook events to Gotify push notifications.

Follows the same pattern as tailscale-webhook-relay: minimal scratch
container, seccomp + read-only rootfs, GOTIFY_URL + GOTIFY_TOKEN env.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(basic-memory): add optional Gateway API HTTPRoute support
- Feat(tailscale-webhook-relay): add optional Gateway API HTTPRoute support
- Feat(cnpg-stack): add cnpg operator/cluster/pooler wrapper chart

fix(cnpg-stack): pin default postgres/pgbouncer images

chore(cnpg-stack): bump chart version to 0.1.3

fix(cnpg-stack): use CNPG-safe image tags and bump 0.1.4
- Feat(cloudflared): improve chart validation and metrics
- Feat: add umami helm chart
- Feat(karakeep): support pod host aliases
- Feat: support karakeep cnpg database url
- Feat(karakeep): support Meilisearch upgrade args
- Feat: use DHI Forgejo job image
- Feat: add m0sh1-exporter chart

### 🐛 Bug Fixes

- Fix(ci): remove semantic-release, use Chart.yaml as version source

semantic-release was creating a parallel version lineage
(cloudflared-v1.6.0) by analysing ALL commits on main, not just
cloudflared changes. The actual chart version (1.2.0 in Chart.yaml)
was correct but the GitHub Release title/tag was wrong.

Release flow is now:
- OCI publish: release-all.yaml pushes all charts to GHCR on push
- GitHub Releases: tag-triggered pipelines (release.yaml, etc.)
  fire on manual `git tag <chart>-v<version>` matching Chart.yaml

Removed: .releaserc.json, package.json, package-lock.json,
semantic-release step from build.yaml.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Fix(wakapi): normalize HTTPRoute parentRefs for Argo sync
- Fix(basic-memory): bump livesync-bridge to sha-9b7f43c, chart 0.1.5→0.1.6

Fixes crash loop: TypeError: getSystemVaultName.setHandler is not a function.
HeadlessAPIService promoted getSystemVaultName to a concrete method in
livesync-commonlib 0.25.54; the fork patch calling .setHandler() on it
crashed at pod startup.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
- Fix(csi-driver-nfs): sync chart with upstream fixes
- Fix(csi-driver-nfs): point chart at next fork image
- Fix(charts): refresh dependencies and image pins
- Fix(basic-memory): bump livesync bridge image
- Fix(karakeep): support Meilisearch upgrade command
- Fix: bump opnsense exporter image
- Fix: bump opnsense exporter image

### 💼 Other

- Add Gateway API HTTPRoute support

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
- Merge branch 'codex/update-nfs-csi-chart-upstream'
- Improve Helm chart validation and docs
- Use Woodpecker for chart validation
- Harden chart defaults and docs
- Add PrivateBin Healthchecks and SearXNG charts
- Add SearXNG Valkey image pull secrets
- Fix SearXNG container port environment
- Use DHI Valkey for searxng
- Add Karakeep Helm chart
- Add Karakeep chart icon
- Merge pull request 'chore(deps): pin dependencies' (#3) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/3
- Merge pull request 'chore(deps): update helm charts' (#4) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/4
- Merge pull request 'chore(deps): update helm charts' (#5) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/5
- Harden Basic Memory runtime sync defaults
- Fix Basic Memory config init directory
- Improve chart validation and pin images
- Allow global values in strict chart schemas
- Merge pull request 'chore(deps): update gitea/runner docker tag to v1.0.4' (#6) from renovate/patch-helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/6
- Merge pull request 'chore(deps): update getmeili/meilisearch docker tag to v1.44.0' (#7) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/7
- Use shell-capable kubeconform CI image
- Call kubeconform by absolute path
- Add proxmox-csi-plugin chart
- Merge pull request 'chore(deps): pin dependencies' (#8) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/8
- Merge pull request 'chore(deps): update helm charts' (#9) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/9
- Merge pull request 'chore(deps): update docker docker tag to v29.5.1' (#10) from renovate/patch-helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/10
- Merge pull request 'chore(deps): update dhi.io/valkey docker tag to v9.1.0' (#11) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/11
- Merge pull request 'chore(deps): pin dhi.io/busybox docker tag to f05f539' (#12) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/12
- Add Forgejo OCI charts
- Use OCI Forgejo runner chart dependency
- Promote Wakapi fork chart
- Merge pull request 'chore(deps): update data.forgejo.org/forgejo/runner docker tag to v12' (#13) from renovate/major-helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/13
- Bump Wakapi chart image digest
- Use custom Forgejo runner image
- Use custom Forgejo runner chart dependency
- Support Forgejo runner namespace override
- Restore helm-charts mise config
- Update Forgejo runner chart to v12 custom image
- Merge pull request 'chore(deps): update helm charts' (#14) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/14
- Merge pull request 'chore(deps): update helm charts (patch)' (#15) from renovate/patch-helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/15
- Merge pull request 'chore(deps): update helm charts' (#16) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/16
- Merge pull request 'chore(deps): update ghcr.io/basicmachines-co/basic-memory docker tag to v0.21.4' (#17) from renovate/patch-helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/17
- Merge pull request 'chore(deps): update cloudflare/cloudflared docker digest to a5b5e6f' (#18) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/18
- Merge pull request 'chore(deps): update helm charts (minor)' (#19) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/19
- Merge pull request 'chore(deps): update ghcr.io/yaelmoshi/proxmox-csi-controller:edge docker digest to 68a9798' (#20) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/20
- Merge pull request 'chore(deps): update helm charts' (#21) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/21
- Merge pull request 'chore(deps): pin dependencies' (#22) from renovate/helm-charts into main

Reviewed-on: https://git.m0sh1.cc/m0sh1/helm-charts/pulls/22

### ⚙️ Miscellaneous Tasks

- Chore: bump cnpg-stack to 0.1.6

Update barman plugin to 0.12.0 for latest features.
- Ci: fix DHI OCI dependency handling

Add DHI registry authentication for OCI dependencies in build/release flows, switch Helm logins to password-stdin, and stop ignoring dependency build failures during publish.\n\nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
- Chore(basic-memory): bump livesync-bridge to sha-b56c0edb (0.1.5)

Updates livesync-bridge image to sha-b56c0edb99e5d4b99fc97cda0e86336af249d832
(livesync-commonlib 0.25.54), which picks up:

- Fix: arrayBufferToBase64 in CLI (Deno 2.x FileReader compat)
- Fixed: HeadlessAPI handles multiple vaults with different names
- Fixed: Journal Sync timing compatibility issue
- Fixed: ServiceFileAccessBase binary file reading
- Fixed: floating awaits, prevent-transfer-twice, conflict resolution

Also corrects the GHCR tag format from bare SHA to sha-<sha> prefix
(matching the actual publish-ghcr workflow output).
- Chore(cloudflared): release chart 1.3.0
- Chore(charts): update cyberchef and gitea runner
- Chore: migrate GitHub handle to yaelmoshi
- Chore: bump SearXNG chart to v0.2.0
- Chore: add updated README for searxng v0.2.1

Includes new installation instructions and updated requirements.
- Chore: bump SearXNG chart to v0.2.2
- Chore: remove deprecated Helm charts

Deleting Argus, CyberChef, Homepage, IT-Tools, and WUD charts and associated configurations for simplification.
- Chore(proxmox-csi): update edge image digests
## [cloudflared-v1.2.0] - 2026-04-11

### 🚀 Features

- Feat(csi-driver-nfs): switch nfsplugin to ghcr.io/sm-moshi/nfsplugin

Custom-built image from sm-moshi/csi-driver-nfs fork with CSI spec
v1.12.0. Replaces upstream registry.k8s.io/sig-storage/nfsplugin.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat: add tailscale-webhook-relay chart

Minimal Helm chart for Tailscale webhook relay to ntfy. Receives
Tailscale webhook events, verifies HMAC signature, formats and
forwards to ntfy with proper title, priority and tags.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(wakapi): add optimised Wakapi Helm chart v1.1.0

Based on ricristian/wakapi-helm-chart v1.0.29 with improvements:

- Extract secrets from ConfigMap into existingSecrets (secretKeyRef)
  for DB password, OIDC credentials, SMTP credentials
- Harden security contexts for distroless (non-root UID 65532,
  readOnlyRootFilesystem, drop ALL caps, seccomp RuntimeDefault)
- Add Prometheus ServiceMonitor template
- Add /tmp emptyDir for writable temp space
- Upgrade HPA to autoscaling/v2
- Simplify Ingress (require k8s >=1.28)
- Add config checksum annotation for automatic rollout
- Default to postgres dialect, persistence disabled, production env

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(wakapi): add WAKAPI_IMPORT_BACKOFF_MIN to ConfigMap

Allows configuring the import cooldown period.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(wakapi): add extraEnv support and bump to 1.1.2

Add extraEnv map for plain environment variables (e.g. TZ) in the
deployment template. Needed to work around upstream bug where the
settings page JS breaks when user timezone contains a slash character.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(wakapi): add patched image build for zoneinfo fix

Build wakapi from upstream commit f5cb4696 which includes the fix for
muety/wakapi#923 — /usr/share/zoneinfo permissions changed from 0444
to 0555, allowing Go's time.LoadLocation() to traverse directories.

Woodpecker pipeline builds linux/amd64+arm64 and pushes to
ghcr.io/sm-moshi/wakapi:2.17.2-patched.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(basic-memory): add chart with optional MCP shim + Obsidian LiveSync profiles

Initial community Helm chart for Basic Memory, the local-first knowledge
graph MCP server. Ships three components:

- Core: upstream basic-memory server, always enabled
- mcpShim: opt-in JSON-RPC normaliser sidecar with write-dir allowlist,
  default-project injection and mutating-tool throttling. Uses the
  livesync-bridge community image as its Deno runtime.
- obsidianSync: opt-in CouchDB + livesync-bridge pair that bidirectionally
  syncs the notes dir with an Obsidian vault via the Self-hosted LiveSync
  plugin.

Includes:

- values.yaml with hardened defaults (HF_HUB_OFFLINE=1, IPv4 SingleStack,
  Recreate strategy, non-root securityContext, fsGroup fix for CouchDB)
- semantic-model-cache-init initContainer that warms the fastembed ONNX
  model once so the runtime can stay offline and avoid HuggingFace
  download corruption on restart
- examples/ for Traefik forward-auth and the full stack
- ci/test-values.yaml for chart-testing
- .woodpecker/release-basic-memory.yaml for tag-triggered GitHub Releases;
  the existing release-all.yaml already publishes to ghcr.io on push

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(cloudflared): add topologySpreadConstraints support

Add topologySpreadConstraints field to the deployment template and
default values. Allows consumers to spread replicas across nodes
using the native Kubernetes scheduling primitive rather than relying
solely on podAntiAffinity.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### 🐛 Bug Fixes

- Fix(ci): remove apk install — DHI helm image is Debian, bash included

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Fix(ci): add helm dep build to OCI publish, scope release to cloudflared

- publish-oci.sh: register dependency repos and run helm dep build
  before lint/package (fixes BJW-S common library resolution)
- build.yaml: restrict semantic-release step to charts/cloudflared/**
  path changes only — was triggering cloudflared version bumps on
  every push to main regardless of which chart changed

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Fix(basic-memory): mcpShim write_note policy reads args.folder

The shim was checking args.directory, but Basic Memory's write_note
MCP tool uses `folder` as the parameter name. With mcpShim.policy
.allowedNoteDirs set to a non-empty list, every write_note call was
silently blocked because normalizeDir(undefined) returned "" which
fails isAllowedDir regardless of allowlist contents.

Check both args.folder and args.directory (older rev alias) so either
spelling works. No chart template changes, just the embedded shim.ts
in the mcp-shim ConfigMap.

Chart 0.1.1 -> 0.1.2.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Fix(renovate): auto-bump chart version on helm-values updates

Adds bumpVersion: "patch" to the Helm package rule so Renovate
automatically increments the chart patch version in Chart.yaml when
it updates image digests or tags in values.yaml. Without this, the
publish-oci.sh script skips the push because the version tag already
exists on GHCR even though the chart content changed.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### 🚜 Refactor

- Refactor: remove BJW-S common library from 6 charts

Replace the bjw-s/common dependency with standalone templates in argus,
cyberchef, gitea-runner, homepage, it-tools, and wud. Each chart now has
its own _helpers.tpl, deployment.yaml, service.yaml, ingress.yaml, and
serviceaccount.yaml modelled on the cloudflared reference chart.

Values are flattened from the BJW-S nested structure (controllers.main.
containers.main.*) to standard Helm conventions (image.*, resources,
securityContext, livenessProbe, etc.). All security contexts, resource
limits, and health probes are preserved in native Kubernetes format.

Special-case handling retained:
- argus: configmap volume mount, optional envFrom secret
- wud: optional envFromSecret
- homepage: multi-file configmap, emptyDir, RBAC (ClusterRole/Binding)
- gitea-runner: two containers (dind + runner), 5 volumes, dynamic env

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Refactor(basic-memory): single livesyncBridge.image source for all sidecars

Adds a top-level `livesyncBridge.image` block that feeds all three
livesync-bridge consumers (mcpShim sidecar, obsidianSync livesync
sidecar, obsidianSync config-init container) via mergeOverwrite. Each
consumer's `.image` subblock defaults to `{}` and inherits the root
block; operators can override any subset of fields (e.g. just `tag`)
without restating the whole reference.

Why:

- Single source of truth — one Renovate entry or argocd-image-updater
  target keeps all three containers in lockstep, no drift risk.
- Clean integration with the infra-repo wrapper chart pattern, where
  image-updater writes back via `helmvalues` to a single path.
- Default tag pinned to a full commit SHA for reproducibility instead
  of `:latest`.

The refactor is backwards-compatible — existing values files that
override `mcpShim.image.{repository,tag,pullPolicy}` etc. keep working
thanks to mergeOverwrite semantics. Resource counts unchanged: 6 core,
11 full-stack.

Chart version 0.1.0 -> 0.1.1.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### 📚 Documentation

- Docs: update README for OCI registry and current chart versions

Replace GitHub Pages instructions with OCI pull/install examples.
Add full chart table with versions and descriptions.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Docs: update chart table with current versions

Add wakapi and tailscale-webhook-relay, bump all chart versions
to match current state.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### ⚙️ Miscellaneous Tasks

- Chore: extend org-wide Renovate base preset (pinDigests: false)
- Chore(renovate): disable digest pinning
- Chore(wakapi): remove Dockerfile and image pipeline

Image builds moved to the sm-moshi/wakapi fork repo. The Dockerfile
and Woodpecker pipeline are no longer needed in helm-charts.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
## [cloudflared-v1.1.0] - 2026-03-30

### 🚀 Features

- Feat(csi-driver-nfs): bump sidecars to upstream master, migrate to DHI

Sync with rebased sm-moshi/csi-driver-nfs fork (now 7 commits ahead
of upstream master, 0 behind).

Image changes:
- csi-provisioner: v6.1.0 → dhi.io 6.2.0
- csi-resizer: v2.0.0 → dhi.io 2.1.0
- csi-snapshotter: v8.4.0 → dhi.io 8.5.0
- csi-node-driver-registrar: v2.15.0 → dhi.io 2.16.0
- livenessprobe: v2.17.0 → dhi.io 2.17.0 (2.18.0 not yet in DHI)
- snapshot-controller: v8.4.0 → dhi.io 8.5.0
- nfsplugin: stays on upstream registry.k8s.io (no DHI image)

Config changes:
- Remove HonorPVReclaimPolicy (upstream removed in c75eb246)
- Chart version 4.13.2 → 4.13.3

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(ci): push charts to GHCR OCI on release

Add an OCI push step after chart-releaser that packages and pushes
all charts to oci://ghcr.io/sm-moshi/charts. Skips versions that
already exist on GHCR.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat(ci): add publish-all pipeline for GHCR OCI chart releases

Packages and pushes all charts to oci://ghcr.io/sm-moshi/charts on
push to main (when charts/ change) or manual trigger. Skips versions
already published to GHCR.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Feat: harden all charts — security contexts, resources, probes

Security contexts added to 6 charts (argus, cyberchef, gitea-runner,
homepage, it-tools, wud) following cloudflared as the reference:
- runAsNonRoot, runAsUser/Group 65532
- readOnlyRootFilesystem, drop ALL capabilities
- Pod-level seccompProfile: RuntimeDefault
- gitea-runner: privileged retained (DinD requirement) but now with
  seccomp and resource constraints

Resource requests/limits added to all 7 charts that were missing them:
- gitea-runner DinD: 4Gi memory limit (critical — unbounded before)
- gitea-runner act_runner: 1Gi memory limit
- cloudflared: 256Mi limit
- Others: 256-512Mi limits appropriate to workload

Health probes added to 6 charts: argus, cyberchef, homepage, it-tools,
wud (HTTP path probes on their respective ports).

Stale appVersions fixed:
- cyberchef: v10.19.4 → v10.22.1
- gitea-runner: 0.2.13 → 0.3.1
- wud: 8.1.1 → 8.2.2

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### 🐛 Bug Fixes

- Fix(ci): move OCI publish logic to bash script

Woodpecker pre-processes ${VAR} in | blocks as env var substitution,
stripping shell-local variables. Move the publish loop to .ci/publish-oci.sh
which runs via `bash` and avoids the pre-processing entirely.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### ⚙️ Miscellaneous Tasks

- Chore(release): cloudflared 1.1.0 [skip ci]

# [1.1.0](https://github.com/sm-moshi/helm-charts/compare/cloudflared-v1.0.0...cloudflared-v1.1.0) (2026-03-24)

### Features

* **csi-driver-nfs:** add forked chart with configurable fsGroupPolicy ([659c2f9](https://github.com/sm-moshi/helm-charts/commit/659c2f9ef9404d0c12d3cf711f4bcd307dabd0b7))
- Chore(release): cloudflared 1.2.0 [skip ci]

# [1.2.0](https://github.com/sm-moshi/helm-charts/compare/cloudflared-v1.1.0...cloudflared-v1.2.0) (2026-03-30)

### Features

* **csi-driver-nfs:** bump sidecars to upstream master, migrate to DHI ([256fabe](https://github.com/sm-moshi/helm-charts/commit/256fabeba3970ddef434580fa33510397b8ac715))
- Chore(release): cloudflared 1.3.0 [skip ci]

# [1.3.0](https://github.com/sm-moshi/helm-charts/compare/cloudflared-v1.2.0...cloudflared-v1.3.0) (2026-03-30)

### Features

* **ci:** push charts to GHCR OCI on release ([2bad482](https://github.com/sm-moshi/helm-charts/commit/2bad482b3e9596b79742c8850d851995da896e27))
- Chore: drop abandoned semantic-release plugins

Remove @semantic-release/changelog (2023) and @semantic-release/git
(2021). SR v25+ bundles commit-analyzer and release-notes-generator.
Release notes go to the GitHub release instead of a committed
CHANGELOG.md.

helm/chart-releaser-action v1.7.0 is still the official Helm project
action — flagged by Renovate due to inactivity but no replacement
exists.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
- Chore: remove redundant GitHub Actions workflows

All CI/CD is handled by Woodpecker pipelines:
- build.yaml: helm lint on push/PR
- release-all.yaml: OCI publish to GHCR on chart changes
- release.yaml / release-nfs-csi.yaml: tag-triggered releases

Removed:
- build.yml: SonarQube scan (not used)
- charts-lint.yaml: chart-testing + kind install (Woodpecker lint covers this)
- charts-release.yaml: chart-releaser GitHub Pages + OCI push (replaced by release-all.yaml)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
## [csi-driver-nfs-v4.13.2] - 2026-03-24

### 🚀 Features

- Feat(csi-driver-nfs): add forked chart with configurable fsGroupPolicy

Port the csi-driver-nfs chart from the sm-moshi fork (based on upstream
v4.13.1) with the key fix: fsGroupPolicy is now configurable via
.Values.feature.fsGroupPolicy instead of being hardcoded to "File".

This allows the infra wrapper chart to set fsGroupPolicy: None for NFS
volumes, preventing kubelet from recursively chowning NFS mounts on
every pod start — which broke non-root writes (e.g. Woodpecker CI cache
volumes with uid 1000).

Add Woodpecker release pipeline for OCI chart publishing to
ghcr.io/sm-moshi/charts on csi-driver-nfs-v* tags.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### 🐛 Bug Fixes

- Fix(ci): add helm dependency build before linting

Charts with subchart dependencies (e.g. bjw-s common library)
need their deps downloaded before linting. Add repo discovery
and helm dependency build to the lint step.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### ⚙️ Miscellaneous Tasks

- Chore(release): cloudflared 1.0.0 [skip ci]

# 1.0.0 (2026-03-23)

### Bug Fixes

* **ci:** add helm dependency build before linting ([576d16e](https://github.com/sm-moshi/helm-charts/commit/576d16e59e0fe3be9568818338c444d9d4bec8ba))

### Features

* **cloudflared:** fork community chart with rolling update fixes ([3dd9d88](https://github.com/sm-moshi/helm-charts/commit/3dd9d88df44031cdbc2ac6356c83f4ac7b2d2267))
## [cloudflared-v1.0.0] - 2026-03-23

### 🚀 Features

- Feat(cloudflared): fork community chart with rolling update fixes

Fork community-charts/cloudflared v2.2.7 with improvements:

- Fix: render Deployment strategy (upstream only renders for DaemonSet)
- Fix: configurable liveness probe (upstream hardcodes failureThreshold: 1)
- Fix: serviceaccount.yaml automountServiceAccountToken indentation
- Add: readiness probe support (prevents premature old pod termination)
- Add: minReadySeconds for rollout stability
- Add: configurable PDB (enable/disable, minAvailable/maxUnavailable)
- Add: extraEnv, extraVolumeMounts, extraVolumes
- Add: podLabels rendering (existed in values but never rendered)
- Rename: port active-con-stat → metrics

Also adds Woodpecker CI pipelines (build + release), semantic-release
for automated OCI chart publishing to ghcr.io/sm-moshi/charts, npm
manager to Renovate config, and fixes helm-lint pre-commit hook for
charts without HTTP dependencies.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>

### 🚜 Refactor

- Refactor(renovate): switch to best-practices, simplify via org-wide base preset

Switch from config:recommended to config:best-practices. Remove
settings now inherited from globalExtends base preset.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
## [gitea-runner-0.2.3] - 2026-03-08

### 💼 Other

- Merge pull request #17 from sm-moshi/renovate/major-github-actions

chore(deps): update github actions (major)
- Potential fix for code scanning alert no. 2: Workflow does not contain permissions

Co-authored-by: Copilot Autofix powered by AI <62310815+github-advanced-security[bot]@users.noreply.github.com>
## [gitea-runner-0.2.2] - 2026-01-19

### 💼 Other

- Initial plan
- Merge pull request #7 from sm-moshi/copilot/update-helm-charts-dependencies

chore(deps): update releaseargus/argus to v0.29.1
- Merge branch 'main' into renovate/patch-helm-charts
- Merge pull request #8 from sm-moshi/renovate/patch-helm-charts
- Merge pull request #9 from sm-moshi/renovate/patch-helm-charts

chore(deps): update helm charts (patch)

### ⚙️ Miscellaneous Tasks

- Chore: add SonarQube CI and refresh tooling

Add SonarQube workflow and project properties, update gitignore entries,
refresh mise tool versions and tasks, reformat cliff config, and bump
gitea-runner chart version plus dind image tag.
## [wud-0.2.0] - 2026-01-08

### 💼 Other

- Bump WUD Helm chart version and update chart dependency

Updates the WUD Helm chart version to 0.2.0, upgrades the shared chart dependency to 4.6.0 and regenerates the lockfile to reflect the new digest. Also refreshes the changelog with recent releases and tooling bumps (including added Helm tasks and linting notes) to keep project metadata and dependency state consistent for future releases.
## [it-tools-0.2.0] - 2026-01-08

### 💼 Other

- Bump: it-tools 0.2.0
## [homepage-0.3.0] - 2026-01-08

### 💼 Other

- Bump: Homepage 0.3.0
## [gitea-runner-0.2.0] - 2026-01-08

### ⚙️ Miscellaneous Tasks

- Chore: bump gitea runner to 0.2.0
## [cyberchef-0.2.0] - 2026-01-08

### ⚙️ Miscellaneous Tasks

- Chore: bump cyberchef to 0.2.0
## [argus-0.5.0] - 2026-01-08

### 💼 Other

- Add Helm tasks and improve linting

Adds dedicated tasks to update Helm chart dependencies and to lint charts, enabling linting of subcharts. Uses the lint flag to include subcharts and provides a scripted task for dependency updates to simplify maintenance.

Also bumps tool versions and the min version constraint to ensure compatibility with the updated hooks and tasks.

### ⚙️ Miscellaneous Tasks

- Chore: Argus 0.5.0
## [gitea-runner-0.1.3] - 2026-01-01

### 💼 Other

- Merge pull request #5 from sm-moshi/renovate/major-github-actions
- Merge pull request #6 from sm-moshi/renovate/github-actions
- Bump gitea-runner
## [cyberchef-0.1.2] - 2025-12-30

### 💼 Other

- Bump: cyberchef 0.1.2
## [wud-0.1.2] - 2025-12-30

### 💼 Other

- Bump: wud 0.1.2
## [wud-0.1.1] - 2025-12-30

### 💼 Other

- Initial plan
- Fix Renovate configuration by removing conflicting matchUpdateTypes

Co-authored-by: sm-moshi <12695314+sm-moshi@users.noreply.github.com>
- Merge pull request #3 from sm-moshi/copilot/fix-renovate-configuration-error

Fix Renovate configuration: remove conflicting matchUpdateTypes
- Update tooling configs for helm-charts

  - add git-cliff and rumdl configs for consistent changelog/markdown linting
  - update mise tool/tasks and pre-commit/yamllint settings
  - adjust CI workflow defaults and ignore patterns
  - touch contributing guidance to match tooling
- Add CyberChef chart
- Add Gitea runner chart
- Add WUD chart
- ~icons
## [argus-0.4.0] - 2025-12-30

### 💼 Other

- Argus helm 0.4.0
## [argus-0.3.0] - 2025-12-30

### 💼 Other

- Bump: argus 0.3.0
## [it-tools-0.1.0] - 2025-12-30

### 💼 Other

- Add Argus Helm chart

  - Add Argus chart using bjw-s/common
  - Provide config/secret helpers and ArgoCD example
  - Include chart lock and vendored dependency
- Added IT-Tools Helm chart
## [homepage-0.2.0] - 2025-12-30

### ⚙️ Miscellaneous Tasks

- Chore(ci): streamline ct config, hooks, docs, and Artifact Hub metadata

  - enable version bump checks and install tests
  - add pre-commit hook wrapper
  - add artifacthub-repo.yml + badges
  - refresh contributing guide and Renovate config
- Chore: implemented testing for homepage chart
## [homepage-0.1.2] - 2025-12-30

### 💼 Other

- Initial commit
- Initial plan
- Set up Helm charts repository structure with example chart and ArgoCD integration

Co-authored-by: sm-moshi <12695314+sm-moshi@users.noreply.github.com>
- Add quick start guide, templates guide, and ArgoCD validation workflow

Co-authored-by: sm-moshi <12695314+sm-moshi@users.noreply.github.com>
- Fix code review issues: containerPort, HTTPRoute path, and App of Apps reference

Co-authored-by: sm-moshi <12695314+sm-moshi@users.noreply.github.com>
- Add permissions blocks to GitHub Actions workflows for security

Co-authored-by: sm-moshi <12695314+sm-moshi@users.noreply.github.com>
- Merge branch 'main' into copilot/add-helm-charts-for-deployment
- Merge pull request #1 from sm-moshi/copilot/add-helm-charts-for-deployment

Set up Helm charts repository with ArgoCD integration
- Create CNAME
- Merge remote-tracking branch 'origin/main'
- Delete CNAME
- Disable Pages build; ensure gh-pages exists for chart releases
- Implemented CI + release flow and pre‑commit hooks
- Bump: homepage chart
- Remove example-app

### ⚙️ Miscellaneous Tasks

- Chore: workflows setup
- Chore: renovate setup
- Chore: Homepage v1.8.0 Helm chart
- Chore: Helm repo setup
- Chore: Helm repo setup + v0.1.1 Homepage Chart
- Chore: cleanup
- Chore: Helm chart repo setup part 321321412
- Chore: workflows
