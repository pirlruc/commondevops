#!/usr/bin/env python3
"""Fail when a workflow pins an older tag of an image this repo published.

The newest GitHub release that names a ghcr.io image is the source of the
current tags. A pin of the same image at a different tag is drift. Images
this repo did not publish are ignored.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

IMAGE = re.compile(r"ghcr\.io/pirlruc/([a-z0-9-]+):([0-9][0-9A-Za-z.\-]*)")
PIN = re.compile(
    r"ghcr\.io/pirlruc/([a-z0-9-]+):([0-9][0-9A-Za-z.\-]*)@sha256:[0-9a-f]{64}"
)


def version_of(tag: str) -> str:
    """6.8.0-debian and 6.8.0-alpine are the same publish as 6.8.0."""
    return tag.split("-", 1)[0]


def newest_image_release() -> str:
    raw = subprocess.check_output(
        [
            "gh",
            "release",
            "list",
            "--limit",
            "20",
            "--json",
            "tagName,isDraft",
        ],
        text=True,
    )
    for item in json.loads(raw):
        if item.get("isDraft"):
            continue
        body = subprocess.check_output(
            ["gh", "release", "view", item["tagName"], "--json", "body", "-q", ".body"],
            text=True,
        )
        if "ghcr.io/pirlruc/" in body:
            return body
    return ""


def main() -> int:
    body = newest_image_release()
    if not body:
        print("no release names a ghcr.io image; nothing to compare")
        return 0
    published: dict[str, set[str]] = {}
    for name, tag in IMAGE.findall(body):
        published.setdefault(name, set()).add(version_of(tag))
    failures: list[str] = []
    root = Path(".github/workflows")
    for path in sorted(root.glob("*.yml")):
        for name, tag in PIN.findall(path.read_text()):
            if name in published and version_of(tag) not in published[name]:
                failures.append(
                    f"{path}: {name}:{tag} is not in the newest image release "
                    f"({', '.join(sorted(published[name]))})"
                )
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"published image tags match ({', '.join(sorted(published))})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
