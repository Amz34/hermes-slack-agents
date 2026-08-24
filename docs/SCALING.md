# Scaling Architecture — the long-term play

Self-hosted multi-tenant systems die from **operational complexity**, not
infrastructure cost. Every client adds a small tax: config drift, permission
sprawl, memory collisions, upgrade risk. This document is the answer to that —
the design rules that keep N clients cheap to run when N is 1 or 100.

## Core principle: control plane vs data plane

```
┌──────────────────────────────┐
│  CONTROL PLANE (shared)      │   one gateway, one codebase, one upgrade path
│  · gateway process           │   · client registry (clients.json)
│  · health monitor            │   · provisioning scripts
│  · deploy pipeline           │
└──────────────┬───────────────┘
               │ isolated profiles
┌──────────────▼───────────────┐
│  DATA PLANE (per client)     │   each client = own process, own state
│  · profile A (bot, memory,   │
│    cron, tokens)             │
│  · profile B (isolated)      │
│  · profile C (isolated)      │
└──────────────────────────────┘
```

- **Customization** lives in the data plane — per-client profiles can diverge
  freely (own memory, own cron, own permissions) without touching shared code.
- **Maintainability** lives in the control plane — one codebase, one upgrade
  path, one monitoring surface.
- The rule: **shared code is immutable, per-client state is disposable.**
  If a client profile can't be deleted and recreated from the registry in
  under a minute, the design has a leak.

## The 5 scaling rules

1. **One command to onboard.** Adding a client must never require manual
   steps beyond the human install approval. See `scripts/client_onboard.sh`.
2. **Registry is the source of truth.** Every client is a single JSON entry
   (id, profile, status, health). No undocumented manual state.
3. **Process isolation per client.** A crashing or misbehaving client bot
   must not take down the gateway or other clients. See
   `systemd/hermes-client@.service` — one template unit, N instances.
4. **Budget everything.** Each profile gets explicit quotas: memory size,
   cron frequency, token usage, log retention. Budgets make scale
   predictable and prevent one noisy client from starving the rest.
5. **Upgrade = fleet, not forklift.** A new gateway version upgrades the
   control plane once; client profiles are schema-versioned so they migrate
   forward independently.

## Customization vs maintainability — decision table

| Situation | Rule |
|---|---|
| Client needs a unique behavior | Data plane: extend profile config, never fork code |
| Two clients need the same behavior | Promote to shared control-plane feature (single PR) |
| Client needs an experimental flag | Profile-level feature flag, default off, documented |
| Behavior breaks the shared contract | Refuse in review — pay down in control plane |

The test for any new requirement: **"can this be expressed as data in the
registry?"** If yes → cheap to scale. If it needs code per client → it's a
fork, and forks are the wall self-hosted setups hit.

## When to stop scaling manually

At ~20 clients the operational surface (upgrades, health, onboarding
throughput) justifies a read-only dashboard and automated health alerts —
not because 20 is magic, but because by then the registry + budgets give you
exact data to automate against. Until then, the scripts in this repo keep
manual load near zero.

*See also: `docs/OPERATIONS.md` for the day-to-day runbook.*
