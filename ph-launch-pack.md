# Product Hunt Launch Pack — Hermes Slack Agents

**Product name:** Hermes Slack Agents
**Repo:** https://github.com/Amz34/hermes-slack-agents

## Tagline (one line, benefit-first)

> Your own private AI agent in Slack — one per client, self-hosted, $0/month

## Description (what → how → who → stack)

Agencies and freelancers juggle client conversations across WhatsApp, Telegram, and Slack — every client asking "what's the status?" at a different time of day. Hermes Slack Agents turns that into a fleet of private AI agents, one per client, each living inside its own Slack workspace.

**What it does:** every client gets their own bot with its own identity, memory, and permissions. Mention the bot in any channel and it answers from your own data — no third-party cloud, no per-seat SaaS fees.

**How it works:** one gateway runs on a single always-free cloud VM. Each client bot is an isolated profile — own tokens, own memory store, own cron jobs. Setup is a one-time flow: create the app from a manifest, the client approves a single install link, and the token exchange happens automatically.

**Who it's for:** agencies, consultants, and product teams who want AI in their clients' Slack workspaces without giving client data to a SaaS vendor.

**Stack:** Python 3.11, Slack Bolt (Socket Mode), Hermes Agent gateway, Oracle Cloud Always-Free. Everything is documented — no dark magic.

## First comment (story + what's next)

Built this because I was running 4 client bots in 4 separate Slack workspaces and managing them by hand. Every client needed their own bot token, their own memory, their own permissions — and nothing off-the-shelf did per-client isolation on a free VM.

So I packaged the whole flow: manifest → install link → auto token exchange → per-profile gateway. One command creates the app, one human click approves it, and the bot is live.

What's next: per-bot memory namespaces, a status dashboard, and a one-command installer (curl | bash). Star the repo if you'd run this for your clients — feedback welcome!

## Topics

Artificial Intelligence · Developer Tools · Open Source · Automation · Self-hosted

## Gallery images

- gallery-1-architecture.png — architecture diagram (gateway → per-client bots)
- gallery-2-terminal.png — terminal mock with real script names

## Product link to submit

https://github.com/Amz34/hermes-slack-agents
