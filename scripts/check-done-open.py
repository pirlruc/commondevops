#!/usr/bin/env python3
"""Fail when a status:done manifest id still has an open GitHub issue.

Token-optional (CMN-RECON-001). With no GH_TOKEN / GITHUB_TOKEN, print the gap
and exit 0. Does not treat a missing network call as a pass of the comparison.
"""

from __future__ import annotations

import http.client
import json
import os
import sys
from urllib.parse import urlparse

import yaml


def done_ids(path: str) -> list[str]:
    with open(path, encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    found: list[str] = []

    def walk(node: object) -> None:
        if isinstance(node, dict):
            if node.get("status") == "done" and isinstance(node.get("id"), str):
                found.append(node["id"])
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for item in node:
                walk(item)

    walk(data)
    return found


def open_titles(repo: str, token: str) -> list[str]:
    titles: list[str] = []
    path = f"/repos/{repo}/issues?state=open&per_page=100"
    while path:
        connection = http.client.HTTPSConnection("api.github.com", timeout=30)
        connection.request(
            "GET",
            path,
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github+json",
                "User-Agent": "commondevops-check-done-open",
            },
        )
        response = connection.getresponse()
        body = response.read()
        link = response.getheader("Link", "")
        connection.close()
        if response.status >= 400:
            raise SystemExit(f"GitHub issues API returned {response.status}")
        payload = json.loads(body)
        if not isinstance(payload, list):
            raise SystemExit("GitHub issues payload was not a list")
        for item in payload:
            if "pull_request" in item:
                continue
            title = item.get("title") or ""
            titles.append(title)
        path = ""
        for part in link.split(","):
            if 'rel="next"' in part:
                next_url = part.split(";")[0].strip().strip("<>")
                parsed = urlparse(next_url)
                if parsed.netloc != "api.github.com":
                    raise SystemExit("GitHub pagination left api.github.com")
                path = parsed.path + (f"?{parsed.query}" if parsed.query else "")
    return titles


def main() -> int:
    manifest = sys.argv[1] if len(sys.argv) > 1 else "docs/issues.yml"
    if not os.path.isfile(manifest):
        print(f"note: {manifest} absent; skipping done-vs-open")
        return 0
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
    if not token:
        print("no token — done-vs-open lookup did not run")
        return 0
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    if not repo:
        print("no GITHUB_REPOSITORY — done-vs-open lookup did not run")
        return 0
    ids = done_ids(manifest)
    try:
        titles = open_titles(repo, token)
    except OSError as exc:
        print(f"error: GitHub issue lookup failed: {exc}", file=sys.stderr)
        return 1
    stale = [item for item in ids if any(f"[{item}]" in title for title in titles)]
    if not stale:
        print(f"done-vs-open: {len(ids)} done ids, none still open")
        return 0
    print("done manifest ids still open:", ", ".join(stale), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
