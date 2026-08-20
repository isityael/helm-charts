#!/usr/bin/env bash
set -euo pipefail

config=renovate.json

jq -e '
  .ignorePaths | index("charts/deprecated/**") != null
' "$config" >/dev/null || {
  echo "Renovate must ignore retired charts so dead registries do not create lookup warnings" >&2
  exit 1
}

jq -e '
  [
    .packageRules[]
    | select(
        .matchManagers == ["helmv3", "helm-values"]
        and .groupName == "{{parentDir}} Helm chart"
        and .groupSlug == "{{parentDir}}-helm-chart"
      )
  ] | length == 1
' "$config" >/dev/null || {
  echo "Renovate must isolate Helm dependency groups by owning chart directory" >&2
  exit 1
}

echo "Renovate chart isolation contract passed"

jq -e '
  [
    .customManagers[]
    | select(.description == "Full image references in the csi-s3 wrapper")
  ] | length == 0
' "$config" >/dev/null || {
  echo "Renovate must not treat the split CSI-S3 tag field as a full image reference" >&2
  exit 1
}

jq -e '
  any(
    .packageRules[];
    .description == "Keep CSI-S3 maintained image tags compatible with ArgoCD Image Updater"
      and .matchManagers == ["helm-values"]
      and .matchFileNames == ["charts/csi-s3/values.yaml"]
      and .matchPackageNames == ["ghcr.io/isityael/csi-s3-driver"]
      and .pinDigests == false
  )
' "$config" >/dev/null || {
  echo "Renovate must update the CSI-S3 tag without appending a digest to it" >&2
  exit 1
}

echo "Renovate CSI-S3 image contract passed"

jq -e '
  any(
    .customManagers[];
    .description == "Youtarr Chart appVersion"
      and .managerFilePatterns == ["/charts/youtarr/Chart\\.yaml$/"]
      and .depNameTemplate == "docker.io/dialmaster/youtarr"
      and .datasourceTemplate == "docker"
  )
' "$config" >/dev/null || {
  echo "Renovate must track the Youtarr Chart appVersion alongside the default image" >&2
  exit 1
}

jq -e '
  any(
    .packageRules[];
    .description == "Keep Youtarr image and appVersion in one update"
      and .matchManagers == ["helm-values", "custom.regex"]
      and .matchPackageNames == ["docker.io/dialmaster/youtarr"]
      and .groupSlug == "youtarr-helm-chart"
  )
' "$config" >/dev/null || {
  echo "Renovate must group the Youtarr image and Chart appVersion updates" >&2
  exit 1
}

echo "Renovate Youtarr appVersion contract passed"
