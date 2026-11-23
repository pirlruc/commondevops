#!/usr/bin/env python3
"""Fail on machine-local paths and links outside an allowlist.

A documentation repository stays generic when it does not name a checkout on
this machine and does not link a product repository. ``--owners`` lists the
GitHub accounts whose links are policed. ``--allowed`` lists ``owner/repo``
globs that may still be linked. ``--exclude`` skips historical files.
"""

from __future__ import annotations

import argparse
import fnmatch
import re
import sys
from pathlib import Path

TEXT_SUFFIXES = {".md", ".mdc", ".yml", ".yaml", ".txt", ".py", ".sh"}
SKIP_DIRS = {".git", "node_modules", ".ci-venv", "_commondevops", ".venv"}
DEFAULT_EXCLUDES = (
    "CHANGELOG.md,docs/issues.yml,docs/ai-agent-handoff.md,docs/guardrails/**"
)
HOME_RE = re.compile(r"(?:/home/|/Users/)[A-Za-z0-9._-]+/")
TILDE_RE = re.compile(r"~/Developer")
LINK_RE = re.compile(r"https://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)")


def parse_csv(raw: str) -> list[str]:
    """Split a comma-separated list and drop empty items."""
    return [part.strip() for part in raw.split(",") if part.strip()]


def _prefix_excluded(rel: str, pattern: str) -> bool:
    """Return whether ``pattern`` is a directory tree that contains ``rel``."""
    if not pattern.endswith("/**"):
        return False
    prefix = pattern[:-3]
    return rel == prefix or rel.startswith(prefix + "/")


def path_excluded(rel: str, patterns: list[str]) -> bool:
    """Return whether ``rel`` matches an exclude pattern."""
    name = rel.rsplit("/", 1)[-1]
    for pattern in patterns:
        if _prefix_excluded(rel, pattern):
            return True
        if "/" not in pattern and name == pattern:
            return True
        if fnmatch.fnmatch(rel, pattern):
            return True
    return False


def repo_allowed(owner: str, repo: str, allowed: list[str]) -> bool:
    """Return whether ``owner/repo`` matches an allow glob."""
    full = f"{owner}/{repo}"
    return any(fnmatch.fnmatch(full, pattern) for pattern in allowed)


def machine_hits(text: str) -> list[str]:
    """Return machine-local path matches."""
    return HOME_RE.findall(text) + TILDE_RE.findall(text)


def link_hits(text: str, owners: set[str], allowed: list[str]) -> list[str]:
    """Return policed links that are outside the allowlist."""
    bad: list[str] = []
    for owner, repo in LINK_RE.findall(text):
        if owner not in owners:
            continue
        if repo_allowed(owner, repo, allowed):
            continue
        bad.append(f"{owner}/{repo}")
    return bad


def iter_files(root: Path, excludes: list[str]) -> list[Path]:
    """Return text files under ``root`` that are not excluded."""
    found: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file() or path.suffix not in TEXT_SUFFIXES:
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        rel = path.relative_to(root).as_posix()
        if path_excluded(rel, excludes):
            continue
        found.append(path)
    return found


def scan_file(path: Path, root: Path, owners: set[str], allowed: list[str]) -> list[str]:
    """Return findings for one file."""
    text = path.read_text(encoding="utf-8", errors="replace")
    rel = path.relative_to(root).as_posix()
    findings = [f"{rel}: machine-local path {hit}" for hit in machine_hits(text)]
    findings.extend(
        f"{rel}: link outside allowlist {hit}" for hit in link_hits(text, owners, allowed)
    )
    return findings


def scan(root: Path, owners: set[str], allowed: list[str], excludes: list[str]) -> list[str]:
    """Return every finding under ``root``."""
    findings: list[str] = []
    for path in iter_files(root, excludes):
        findings.extend(scan_file(path, root, owners, allowed))
    return findings


def build_parser() -> argparse.ArgumentParser:
    """Return the CLI parser."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--owners", default="")
    parser.add_argument("--allowed", default="")
    parser.add_argument("--exclude", default=DEFAULT_EXCLUDES)
    return parser


def main(argv: list[str] | None = None) -> int:
    """Scan ``--root`` and exit 1 when a finding exists."""
    args = build_parser().parse_args(argv)
    findings = scan(
        Path(args.root),
        set(parse_csv(args.owners)),
        parse_csv(args.allowed),
        parse_csv(args.exclude),
    )
    if not findings:
        print("doc hygiene check ok")
        return 0
    for line in findings:
        print(f"error: {line}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
