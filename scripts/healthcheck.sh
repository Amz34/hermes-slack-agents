#!/usr/bin/env bash
# healthcheck.sh — fleet health in one command.
#
# Exit codes: 0 = healthy, 1 = degraded, 2 = down.
#   ./scripts/healthcheck.sh --all     # every registered client
#   ./scripts/healthcheck.sh <client>  # single client, JSON output
#
# Wire into cron/alerting: two consecutive failures should page someone.

set -euo pipefail

REGISTRY="${REGISTRY:-config/clients.json}"

[ -f "$REGISTRY" ] || { echo "no registry at $REGISTRY" >&2; exit 2; }

check_client() {
  local cid="$1" status="down"
  if systemctl is-active --quiet "hermes-client@${cid}" 2>/dev/null; then
    status="up"
  elif [ -d "profiles/${cid}" ]; then
    status="degraded"   # profile exists but process not running
  fi
  [ "${2:-}" = "--json" ] && { printf '{"client":"%s","status":"%s"}\n' "$cid" "$status"; return; }
  printf '%-24s %s\n' "$cid" "$status"
  [ "$status" = "up" ] && return 0
  [ "$status" = "degraded" ] && return 1
  return 2
}

if [ "${1:-}" = "--all" ]; then
  python3 -c "import json;[print(c['id']) for c in json.load(open('$REGISTRY'))['clients']]" \
    | while read -r cid; do check_client "$cid" || true; done
  exit 0
fi

[ $# -ge 1 ] || { echo "usage: $0 --all | <client-id> [--json]" >&2; exit 2; }
check_client "$1" "${2:-}"
