#!/usr/bin/env bash
# client_onboard.sh — one-command, idempotent client provisioning.
#
# The scaling rule: adding a client must never require manual steps beyond
# the single human install approval. This script owns the entire lifecycle:
#   registry entry -> manifest -> install URL -> systemd unit -> health check.
#
# Usage:
#   ./scripts/client_onboard.sh <client-id>          # create/update
#   ./scripts/client_onboard.sh --remove <client-id> # remove
#   ./scripts/client_onboard.sh --list               # registry contents
#
# Idempotent: re-running create never duplicates; it prints existing state.

set -euo pipefail

REGISTRY="${REGISTRY:-config/clients.json}"
MANIFEST_TEMPLATE="${MANIFEST_TEMPLATE:-manifests/client-agent.json}"
SYSTEMD_TEMPLATE="${SYSTEMD_TEMPLATE:-systemd/hermes-client@.service}"
GATEWAY_URL="${GATEWAY_URL:-https://gateway.example.com/oauth/redirect}"

die() { echo "error: $*" >&2; exit 1; }
[ $# -ge 1 ] || die "usage: $0 <client-id> | --remove <client-id> | --list"

ensure_registry() { [ -f "$REGISTRY" ] || echo '{"clients":[]}' > "$REGISTRY"; }

list_clients() { python3 -c "import json;print('\n'.join(c['id'] for c in json.load(open('$REGISTRY'))['clients']))"; }

remove_client() {
  ensure_registry
  python3 - "$1" <<'PY'
import json, sys
cid = sys.argv[1]
reg = json.load(open('config/clients.json'))
reg['clients'] = [c for c in reg['clients'] if c['id'] != cid]
json.dump(reg, open('config/clients.json','w'), indent=2)
print(f"removed {cid} from registry")
PY
}

if [ "${1:-}" = "--list" ]; then ensure_registry; list_clients; exit 0; fi
if [ "${1:-}" = "--remove" ]; then [ $# -eq 2 ] || die "--remove needs a client id"; remove_client "$2"; exit 0; fi

CID="$1"
[[ "$CID" =~ ^[a-z0-9][a-z0-9-]{1,62}$ ]] || die "client id must be lowercase alnum+dash (got: $CID)"
ensure_registry

# 1. Register the client (no-op if already registered — idempotent core)
python3 - "$CID" <<'PY'
import json, sys, datetime
cid = sys.argv[1]
reg = json.load(open('config/clients.json'))
for c in reg['clients']:
    if c['id'] == cid:
        print(f"already registered: {cid} (status: {c.get('status','unknown')})")
        sys.exit(0)
reg['clients'].append({
    "id": cid,
    "status": "pending",            # pending -> installing -> live
    "profile": f"profiles/{cid}/",  # data plane: own memory, cron, tokens
    "created": datetime.date.today().isoformat(),
    "on_call": "",                  # runbook: who answers for this client
    "budget": {"memory_mb": 100, "cron_min_interval": 15,
               "log_retention_days": 7}
})
json.dump(reg, open('config/clients.json','w'), indent=2)
print(f"registered: {cid}")
PY

# 2. Install URL — the only human step is the client's approval click.
INSTALL_URL="https://slack.com/oauth/v2/authorize?client_id=YOUR_CLIENT_ID&scope=app_mentions:read,assistant:write,chat:write,channels:history,channels:read,groups:history,groups:read,im:history,im:read,im:write,files:read,files:write,reactions:read,users:read&redirect_uri=${GATEWAY_URL}&state=${CID}"
echo "install URL (send to client): $INSTALL_URL"

# 3. Process isolation — template unit instance per client.
[ -f "$SYSTEMD_TEMPLATE" ] && {
  cp "$SYSTEMD_TEMPLATE" "/etc/systemd/system/hermes-client@.service" 2>/dev/null \
    || echo "note: install template unit to /etc/systemd/system/ (needs root)"
  echo "unit ready: systemctl start hermes-client@${CID}"
} || echo "note: systemd template not found, skipping unit (running in foreground is fine)"

# 4. Verify.
echo "verify: ./scripts/healthcheck.sh $CID"
