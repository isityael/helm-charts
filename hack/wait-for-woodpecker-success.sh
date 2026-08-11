#!/bin/sh
set -eu
sha="${1:?}"; shift; : "${FORGEJO_API_URL:?}" "${FORGEJO_REPOSITORY:?}" "${FORGEJO_TOKEN:?}"
i=1; max="${WOODPECKER_GATE_MAX_ATTEMPTS:-240}"; delay="${WOODPECKER_GATE_SLEEP_SECONDS:-15}"
while [ "$i" -le "$max" ]; do
  json="$(curl -fsS -H "Authorization: token ${FORGEJO_TOKEN}" "${FORGEJO_API_URL}/repos/${FORGEJO_REPOSITORY}/statuses/${sha}?limit=100")"; wait=0
  for c in "$@"; do s="$(printf %s "$json"|jq -r --arg c "$c" '[.[]|select(.context==$c)][0].status//"missing"')"; case "$s" in success) echo "$c: success";; failure|error|killed|cancelled|canceled) echo "$c: $s" >&2; exit 1;; *) echo "$c: $s; waiting"; wait=1;; esac; done
  [ "$wait" -eq 1 ] || exit 0; [ "$i" -lt "$max" ] || break; sleep "$delay"; i=$((i+1))
done
echo "Woodpecker status gate timed out for $sha" >&2; exit 1
