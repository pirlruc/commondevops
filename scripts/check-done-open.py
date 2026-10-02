#!/usr/bin/env python3
"""Fail when a status:done manifest id still has an open GitHub issue.

Token-optional (CMN-RECON-001). With no GH_TOKEN / GITHUB_TOKEN, print the gap
and exit 0. Does not treat a missing network call as a pass of the comparison.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

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
    """List open issue titles via the gh CLI, which the CI runner already has."""
    titles: list[str] = []
    page = 1
    env = os.environ.copy()
    env["GH_TOKEN"] = token
    while True:
        completed = subprocess.run(
            [
                "gh",
                "api",
                f"repos/{repo}/issues?state=open&per_page=100&page={page}",
            ],
            check=False,
            capture_output=True,
            text=True,
            env=env,
            timeout=30,
        )
        if completed.returncode != 0:
            raise SystemExit(completed.stderr.strip() or "gh api failed")
        payload = json.loads(completed.stdout)
        if not isinstance(payload, list):
            raise SystemExit("GitHub issues payload was not a list")
        if not payload:
            break
        for item in payload:
            if "pull_request" in item:
                continue
            titles.append(item.get("title") or "")
        if len(payload) < 100:
            break
        page += 1
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
    except (OSError, json.JSONDecodeError, subprocess.TimeoutExpired) as exc:
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
