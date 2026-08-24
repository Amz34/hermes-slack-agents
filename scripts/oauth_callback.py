#!/usr/bin/env python3
"""Slack OAuth callback server — captures the install code after the user clicks Approve.

Run:  python3 scripts/oauth_callback.py
Then open the install URL (see scripts/install_url.py). The code is printed
to stdout and saved to the state file for scripts/exchange_code.py.
"""
import json
import http.server
import os
import urllib.parse

STATE_FILE = os.environ.get("SLACK_STATE_FILE", "install-state.json")


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        code = qs.get("code", [None])[0]
        state = qs.get("state", ["unknown"])[0]
        error = qs.get("error", [None])[0]
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        if error:
            self.wfile.write(f"<h2>Installation error: {error}</h2>".encode())
            print(f"OAUTH_ERROR state={state} error={error}", flush=True)
            return
        if code:
            self.wfile.write(b"<h2>Installation approved! You can close this tab now.</h2>")
            record = {}
            if os.path.exists(STATE_FILE):
                record = json.load(open(STATE_FILE))
            record[state] = {"code": code}
            json.dump(record, open(STATE_FILE, "w"), indent=2)
            print(f"OAUTH_CODE state={state} saved to {STATE_FILE}", flush=True)
        else:
            self.wfile.write(b"<h2>No code received.</h2>")

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    port = int(os.environ.get("SLACK_CALLBACK_PORT", "8845"))
    server = http.server.HTTPServer(("0.0.0.0", port), Handler)
    print(f"READY: callback server on :{port}", flush=True)
    server.serve_forever()
