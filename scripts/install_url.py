#!/usr/bin/env python3
"""Build the Slack install URL for a client agent.

Usage:  python3 scripts/install_url.py --state <agent_name> [--redirect <url>]
Env:    SLACK_CLIENT_ID (required), SLACK_REDIRECT_URL (optional)
"""
import argparse
import os
import urllib.parse

SCOPES = [
    "app_mentions:read", "assistant:write", "channels:history",
    "channels:read", "chat:write", "commands", "files:read", "files:write",
    "groups:history", "groups:read", "im:history", "im:read", "im:write",
    "mpim:history", "mpim:read", "reactions:read", "users:read",
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", required=True, help="agent name (e.g. client-a)")
    ap.add_argument("--redirect", default=os.environ.get("SLACK_REDIRECT_URL", ""))
    args = ap.parse_args()

    client_id = os.environ["SLACK_CLIENT_ID"]
    params = {
        "client_id": client_id,
        "scope": ",".join(SCOPES),
        "state": args.state,
    }
    if args.redirect:
        params["redirect_uri"] = args.redirect

    print("https://slack.com/oauth/v2/authorize?" + urllib.parse.urlencode(params))


if __name__ == "__main__":
    main()
