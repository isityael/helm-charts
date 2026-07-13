#!/usr/bin/env bash
set -euo pipefail

config=renovate.json

jq -e '
  .enabledManagers | index("custom.regex") != null
' "$config" >/dev/null

jq -e '
  any(
    .packageRules[];
    .description == "Keep matrix-umbrella split image digests out of tag values"
      and .matchManagers == ["helm-values"]
      and .pinDigests == false
  )
' "$config" >/dev/null

jq -e '
  any(
    .customManagers[];
    .description == "Matrix umbrella images with sibling digest keys"
      and (.matchStrings | length) > 0
      and ([.matchStrings[] | contains("(?<currentDigest>sha256:")] | all)
  )
' "$config" >/dev/null

if yq -r '.. | select(type == "!!map" and has("tag") and has("digest")) | .tag' \
  charts/matrix-umbrella/values.yaml | grep -n '@sha256:'; then
  echo "matrix-umbrella split image values must keep digests out of tag fields" >&2
  exit 1
fi
