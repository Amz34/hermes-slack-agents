# Hermes Slack Agents

**Give every client its own AI agent in Slack — one gateway, per-client bots, zero SaaS fees.**

![Python](https://img.shields.io/badge/Python-3.11%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Self-hosted](https://img.shields.io/badge/Self--hosted-Yes-brightgreen)

Run a fleet of Slack bots from one machine — each client gets an isolated agent with its own identity, memory, and permissions. Built on the Hermes Agent gateway.

## Why

- **One client = one bot.** Each bot has its own token, its own profile, its own memory — no cross-client data leaks.
- **Private by design.** Every bot lives inside its own workspace. Nothing is public, nothing leaves the workspace.
- **One-time setup.** Create the app → user approves one link → token exchange happens automatically.
- **Free.** No SaaS per-seat fees. Runs on a single always-free cloud VM.

## Architecture

```
┌─────────────────────────── Cloud VM (always-free) ───────────────────────────┐
│                                                                              │
│  Hermes gateway (default) ──── Telegram / WhatsApp / Signal                   │
│                                                                              │
│  Profile: client-a ── gateway ── Slack bot A (workspace A)                    │
│  Profile: client-b ── gateway ── Slack bot B (workspace B)                    │
│  Profile: client-c ── gateway ── Slack bot C (workspace C)                    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

Each profile is an isolated agent: own `.env` (tokens), own memory store, own cron jobs.

## Quickstart

```bash
# 1. Clone
git clone https://github.com/Amz34/hermes-slack-agents.git && cd hermes-slack-agents

# 2. Copy env template
cp .env.example .env   # fill in SLACK_CLIENT_ID / SLACK_CLIENT_SECRET / SLACK_SIGNING_SECRET

# 3. Create the Slack app from the manifest (one command)
slack app create --manifest manifests/client-agent.json

# 4. Start the OAuth callback server (captures the install code)
python3 scripts/oauth_callback.py &

# 5. Open the install URL, user clicks Approve (2 minutes, human step)
python3 scripts/install_url.py --state client-a
# → https://slack.com/oauth/v2/authorize?client_id=...&state=client-a

# 6. Exchange the captured code for a bot token
python3 scripts/exchange_code.py "<code>" client-a
# → EXCHANGE OK: client-a bot_token=xoxb-... bot_user_id=U0...

# 7. Wire the bot token + an app-level token (xapp-) into the profile .env
#    and start the profile gateway. Bot is live.
```

## Files

| Path | Purpose |
|---|---|
| `manifests/client-agent.json` | Slack app manifest (scopes, events, Socket Mode) |
| `scripts/oauth_callback.py` | OAuth code capture server (localhost:8845) |
| `scripts/exchange_code.py` | Code → bot token exchange + state save |
| `scripts/install_url.py` | Builds the per-client install URL |
| `.env.example` | Required env vars |

## Security

- Tokens live only in profile `.env` files (0600 perms) — never in the repo.
- Public repos contain **zero client data, zero tokens** — just the pattern.
- Install approval is always a human step (Slack platform requirement).
- App-level tokens (`xapp-`) are generated from the Slack dashboard only — no API route exists (verified).

## License

MIT — use it, fork it, ship it.
