#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="${repo_root}/charts/basic-memory"
for shim in true false; do
  container="$(helm template basic-memory "${chart}" --set "mcpShim.enabled=${shim}" |
    yq eval-all -o=json -I=0 'select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.name == "basic-memory")')"
  if [ "${shim}" = true ]; then
    expected_host=127.0.0.1
    for probe in startupProbe livenessProbe readinessProbe; do
      [ "$(yq -r ".${probe}.exec.command[0]" <<<"${container}")" = /app/.venv/bin/python ]
      yq -r ".${probe}.exec.command[2]" <<<"${container}" | grep -q "127.0.0.1"
      [ "$(yq -r ".${probe}.tcpSocket // null" <<<"${container}")" = null ]
    done
  else
    expected_host=0.0.0.0
    for probe in startupProbe livenessProbe readinessProbe; do
      [ "$(yq -r ".${probe}.tcpSocket.port" <<<"${container}")" = 8001 ]
    done
  fi
  [ "$(yq -r '.command[5]' <<<"${container}")" = "${expected_host}" ]
done
echo "basic-memory server binding and probe contract passed"
