#!/usr/bin/env bash
set -euo pipefail

config=renovate.json

jq -e '
  .extends | index("local>isityael/infra//.github/renovate/base.json") != null
' "$config" >/dev/null

jq -e '
  .enabledManagers | index("custom.regex") != null
' "$config" >/dev/null

jq -e '
  any(
    .packageRules[];
    .description == "Let custom regex own images with sibling digest keys"
      and .matchManagers == ["helm-values"]
      and (.matchFileNames | index("charts/matrix-umbrella/values*.yaml")) != null
      and (.matchFileNames | index("charts/youtarr/values*.yaml")) != null
      and (.matchPackageNames | index("dhi.io/mariadb")) != null
      and .enabled == false
  )
' "$config" >/dev/null

jq -e '
  any(
    .customManagers[];
    .description == "Combined repository images with sibling digest keys"
      and (.managerFilePatterns | index("/charts/matrix-umbrella/values(?:-[^/]+)?\\.yaml$/")) != null
      and (.managerFilePatterns | index("/charts/youtarr/values(?:-[^/]+)?\\.yaml$/")) != null
      and ([.matchStrings[] | contains("(?<depName>")] | all)
      and ([.matchStrings[] | contains("(?<repository>")] | any | not)
      and (has("autoReplaceStringTemplate") | not)
  )
  and any(
    .customManagers[];
    .description == "Split registry images with sibling digest keys"
      and (.managerFilePatterns | index("/charts/matrix-umbrella/values(?:-[^/]+)?\\.yaml$/")) != null
      and (.matchStrings | length) > 0
      and ([.matchStrings[] | contains("(?<currentDigest>sha256:")] | all)
      and ([.matchStrings[] | contains("(?<imageRegistry>")] | all)
      and ([.matchStrings[] | contains("(?<imageRepository>")] | all)
      and ([.matchStrings[] | contains("(?<registry>")] | any | not)
      and ([.matchStrings[] | contains("(?<repository>")] | any | not)
      and (.depNameTemplate | contains("imageRegistry"))
      and (.depNameTemplate | contains("imageRepository"))
      and (has("autoReplaceStringTemplate") | not)
  )
' "$config" >/dev/null

for values_file in charts/matrix-umbrella/values.yaml charts/youtarr/values.yaml; do
  if yq -r '.. | select(type == "!!map" and has("tag") and has("digest") and .digest != null and .digest != "") | .tag' \
    "$values_file" | grep -n '@sha256:'; then
    echo "${values_file}: split image values must keep digests out of tag fields" >&2
    exit 1
  fi
done
