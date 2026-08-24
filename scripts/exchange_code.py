#!/usr/bin/env python3
"""Exchange a Slack OAuth code for a bot token.

Usage:  python3 scripts/exchange_code.py <code> <agent_name>
Env:    SLACK_CLIENT_ID, SLACK_CLIENT_SECRET, SLACK_STATE_FILE (optional)
"""
import json
import os
import subprocess
import sys

STATE_FILE = os.environ.get("SLACK_STATE_FILE", "install-state.json")


def main():
    code, name = sys.argv[1], sys.argv[2]
    client_id = os.environ["SLACK_CLIENT_ID"]
    client_secret = os.environ["SLACK_CLIENT_SECRET"]

    r = subprocess.run(
        ["curl", "-s", "-X", "POST", "https://slack.com/api/oauth.v2.access",
         "-d", f"client_id={client_id}",
         "-d", f"client_secret={client_secret}",
         "-d", f"code={code}"],
        capture_output=True, text=True)
    resp = json.loads(r.stdout)
    if not resp.get("ok"):
        print("EXCHANGE FAIL:", resp.get("error"), resp.get("details", ""))
        return 1

    result = {
        "app_id": resp.get("app_id"),
        "team": resp.get("team", {}).get("name"),
        "team_id": resp.get("team", {}).get("id"),
        "bot_user_id": resp.get("bot_user_id"),
        "bot_token": resp.get("access_token"),
        "bot_refresh_token": resp.get("refresh_token"),
        "scope": resp.get("scope"),
    }
    record = {}
    if os.path.exists(STATE_FILE):
        record = json.load(open(STATE_FILE))
    record[name] = result
    json.dump(record, open(STATE_FILE, "w"), indent=2)
    os.chmod(STATE_FILE, 0o600)
    print(f"EXCHANGE OK: {name} bot_token={result['bot_token'][:10]}... bot_user_id={result['bot_user_id']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
