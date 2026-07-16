#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/forgejo-runner"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

render_deployment() {
  local output="$1"
  shift

  helm template forgejo-runner "$chart" "$@" >"$output"
}

test_registry_auth_follows_docker_config() {
  local rendered="${tmpdir}/registry-auth.yaml"
  local docker_config
  local registry_auth_mount

  render_deployment "$rendered" --set registryAuthSecret=registry-auth

  docker_config="$(
    yq eval-all '
      select(.kind == "Deployment") |
      .spec.template.spec.containers[] |
      select(.name == "runner") |
      .env[] |
      select(.name == "DOCKER_CONFIG") |
      .value
    ' "$rendered"
  )"
  registry_auth_mount="$(
    yq eval-all '
      select(.kind == "Deployment") |
      .spec.template.spec.containers[] |
      select(.name == "runner") |
      .volumeMounts[] |
      select(.name == "registry-auth") |
      .mountPath
    ' "$rendered"
  )"

  [ "$registry_auth_mount" = "${docker_config}/config.json" ] ||
    fail "expected registry auth at ${docker_config}/config.json, got ${registry_auth_mount}"
}

test_explicit_docker_config_override_is_preserved() {
  local rendered="${tmpdir}/docker-config-override.yaml"
  local docker_config
  local docker_config_count
  local registry_auth_mount

  render_deployment "$rendered" \
    --set registryAuthSecret=registry-auth \
    --set-json 'runner.extraEnv=[{"name":"DOCKER_CONFIG","value":"/custom/docker"}]'

  docker_config="$(
    yq eval-all '
      select(.kind == "Deployment") |
      .spec.template.spec.containers[] |
      select(.name == "runner") |
      .env[] |
      select(.name == "DOCKER_CONFIG") |
      .value
    ' "$rendered"
  )"
  docker_config_count="$(printf '%s\n' "$docker_config" | grep -c .)"
  registry_auth_mount="$(
    yq eval-all '
      select(.kind == "Deployment") |
      .spec.template.spec.containers[] |
      select(.name == "runner") |
      .volumeMounts[] |
      select(.name == "registry-auth") |
      .mountPath
    ' "$rendered"
  )"

  [ "$docker_config_count" = "1" ] || fail "expected one DOCKER_CONFIG entry, got ${docker_config_count}"
  [ "$docker_config" = "/custom/docker" ] || fail "expected explicit DOCKER_CONFIG override to be preserved"
  [ "$registry_auth_mount" = "${docker_config}/config.json" ] ||
    fail "expected registry auth to follow explicit DOCKER_CONFIG, got ${registry_auth_mount}"
}

test_zero_replicas_are_preserved() {
  local rendered="${tmpdir}/zero-replicas.yaml"
  local replicas

  render_deployment "$rendered" --set replicaCount=0
  replicas="$(yq eval-all 'select(.kind == "Deployment") | .spec.replicas' "$rendered")"

  [ "$replicas" = "0" ] || fail "expected replicas 0, got ${replicas}"
}

test_registry_auth_follows_docker_config
test_explicit_docker_config_override_is_preserved
test_zero_replicas_are_preserved

echo "forgejo-runner contract tests passed"
