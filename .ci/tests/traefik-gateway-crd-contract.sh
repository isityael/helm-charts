#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/traefik"
rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT

helm template traefik "${chart}" >"${rendered}"

for crd in \
  tcproutes.gateway.networking.k8s.io \
  tlsroutes.gateway.networking.k8s.io; do
  sync_options="$(
    CRD_NAME="${crd}" yq eval-all '
      select(
        .kind == "CustomResourceDefinition" and
        .metadata.name == strenv(CRD_NAME)
      ) |
      .metadata.annotations."argocd.argoproj.io/sync-options"
    ' "${rendered}"
  )"

  grep -Eq '(^|,)Prune=false(,|$)' <<<"${sync_options}" || {
    echo "FAIL: ${crd} must disable ArgoCD pruning" >&2
    exit 1
  }
  grep -Eq '(^|,)ServerSideApply=true(,|$)' <<<"${sync_options}" || {
    echo "FAIL: ${crd} must use ArgoCD server-side apply" >&2
    exit 1
  }
done

echo "Traefik Gateway API CRD protection contract passed"
