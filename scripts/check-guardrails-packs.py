#!/usr/bin/env python3
"""Fail when a language in the tree has no docs/guardrails pack (GS-PACK-001).

Vendored from github-scaffold scripts/check-guardrails-packs.py at scaffold
1.12.0. The scaffold pin is private and GUARDRAILS_READ_TOKEN cannot read it.
"""

from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path

_SKIP = {
    ".git",
    "docs/guardrails",
    ".github/scaffold",
    "node_modules",
    "build",
    "build-host",
    "third_party",
    "vendor",
    ".venv",
}

# A manifest or extension that means the language is in use, and the pack dir it needs.
_RULES: tuple[tuple[str, str], ...] = (
    ("*.cpp", "cpp"),
    ("*.cc", "cpp"),
    ("*.cxx", "cpp"),
    ("*.hpp", "cpp"),
    ("pyproject.toml", "python"),
    ("setup.py", "python"),
    ("*.kt", "kotlin"),
    ("build.gradle", "kotlin"),
    ("build.gradle.kts", "kotlin"),
    ("*.java", "java"),
    ("*.swift", "swift"),
    ("Package.swift", "swift"),
    ("Dockerfile", "docker"),
    ("Dockerfile.*", "docker"),
    ("*.tf", "opentofu"),
    ("*.proto", "protobuf"),
    ("ansible.cfg", "ansible"),
    ("go.mod", "go"),
    ("Cargo.toml", "rust"),
    ("package.json", "node"),
)


def _skipped(path: Path, root: Path) -> bool:
    """True when path sits under a tree this check does not own."""
    rel = path.relative_to(root).as_posix()
    return any(rel == name or rel.startswith(f"{name}/") for name in _SKIP)


def languages_in_use(root: Path) -> set[str]:
    """Return pack names implied by manifests and source files under root."""
    found: set[str] = set()
    for pattern, pack in _RULES:
        for path in root.rglob(pattern):
            if not path.is_file() or _skipped(path, root):
                continue
            rel = path.relative_to(root).as_posix()
            if pack == "node" and rel.startswith(".github/dependencies/"):
                continue
            found.add(pack)
    return found


def missing_packs(root: Path) -> list[str]:
    """Return languages in use that have no guardrails.md in the pin."""
    used = languages_in_use(root)
    if not used:
        return []
    guardrails = root / "docs" / "guardrails"
    if not guardrails.is_dir():
        return sorted(used)
    missing = []
    for pack in sorted(used):
        if not (guardrails / pack / "guardrails.md").is_file():
            missing.append(pack)
    return missing


def main(argv: list[str] | None = None) -> int:
    """CLI entry. --self-test uses a temporary tree and does not scan the repo."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(argv)
    if args.self_test:
        return _self_test()
    missing = missing_packs(args.root.resolve())
    if missing:
        joined = ", ".join(missing)
        print(f"error: language in use has no docs/guardrails pack: {joined}", file=sys.stderr)
        return 1
    print("guardrails packs ok")
    return 0


def _write(path: Path, text: str = "x\n") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def _self_test() -> int:
    """A language with no pack fails. A covered language and an empty tree pass."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _write(root / "src" / "a.cpp")
        if missing_packs(root) != ["cpp"]:
            print("error: missing cpp pack was not reported", file=sys.stderr)
            return 1
        _write(root / "docs" / "guardrails" / "cpp" / "guardrails.md", "# C++\n")
        if missing_packs(root):
            print("error: present cpp pack was reported missing", file=sys.stderr)
            return 1
        empty = root / "empty"
        empty.mkdir()
        if missing_packs(empty):
            print("error: a tree with no language failed", file=sys.stderr)
            return 1
    print("guardrails pack self-test ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
