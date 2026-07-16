#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/traefik"
rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT

helm template traefik "${chart}" >"${rendered}"

gateway_crd_count="$(
  yq eval-all '
    [
      select(
        .kind == "CustomResourceDefinition" and
        .spec.group == "gateway.networking.k8s.io"
      )
    ] |
    length
  ' "${rendered}"
)"

[[ "${gateway_crd_count}" == "0" ]] || {
  echo "FAIL: Traefik chart rendered ${gateway_crd_count} Gateway API CRD(s); expected zero" >&2
  exit 1
}

echo "Traefik external Gateway API CRD contract passed"
