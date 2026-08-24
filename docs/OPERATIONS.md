# Operations Runbook

Day-to-day operations for a multi-client gateway. Every procedure here is
designed around the scaling rules in `SCALING.md` — registry as source of
truth, one-command onboarding, process isolation.

## Client lifecycle

### Onboard a new client (≈2 minutes, 1 human click)

```bash
# 1. One command — creates manifest, registers client, prints install URL
./scripts/client_onboard.sh acme-corp

# 2. Human step: client approves the install link (the only manual step)
# 3. Verify
systemctl status hermes-client@acme-corp --no-pager
./scripts/healthcheck.sh acme-corp
```

The onboarding script is **idempotent** — re-running it never creates
duplicates; it prints the existing state and install URL.

### Remove a client

```bash
systemctl disable --now hermes-client@acme-corp
./scripts/client_onboard.sh --remove acme-corp   # removes registry entry
```

Removal is fully reversible: re-run onboarding to recreate from the same
registry schema (per-client data is disposable by design).

## Health monitoring

```bash
./scripts/healthcheck.sh --all        # every registered client, one pass
./scripts/healthcheck.sh <client>     # single client, JSON output
```

- Exit code 0 = healthy, 1 = degraded, 2 = down.
- Wire this into cron or your alerting tool; a client that fails health
  twice in a row should page someone — silent failure is the real cost of
  self-hosting.

## Upgrades

1. Upgrade the gateway (control plane) — one deploy, zero per-client steps.
2. Run `./scripts/healthcheck.sh --all` — fleet must be green.
3. Client profiles are schema-versioned; a profile on an older schema logs
   a clear "migrate me" warning instead of failing silently.

## Backup

- `config/clients.json` is the only irreplaceable control-plane state —
  back it up (it's small, back it up often).
- Per-client profile data is disposable (rebuildable from the registry +
  reinstall), but back it up anyway if the client pays for continuity.

## Budget enforcement

Per-client quotas live in the registry (`config/clients.example.json`).
Defaults:

| Resource | Default budget |
|---|---|
| Memory store | 100 MB |
| Cron frequency | min 15 min interval |
| Log retention | 7 days |
| Token spend | warn at 80%, hard-stop configurable |

Budgets are advisory at small scale, enforced at large scale — but set them
from day one so the data exists before you need it.

*Questions the runbook should answer before you need them: who is the
on-call contact for client X? Where does client X's data live? What does
"healthy" mean for client X? The registry schema has fields for all three.*
