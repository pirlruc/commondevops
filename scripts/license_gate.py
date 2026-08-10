#!/usr/bin/env python3
"""Fail if SPDX SBOM contains a denied license (substring match, case-insensitive).

Deny list resolution order:

1. ``LICENSE_DENY_LIST`` env (JSON array string) when non-empty and not ``[]``
2. ``license_deny_list`` from ``docs/guardrails/supply-chain/profile.thresholds.yml``
   (or ``THRESHOLDS_PATH`` override)
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path
from typing import Any


def _parse_deny_list(raw: str) -> list[str]:
    """Return normalized lowercase deny substrings from a JSON array string.

    Only string entries are used; ``null``, numbers, and other types are skipped so malformed
    values cannot become accidental patterns (e.g. ``"none"`` from ``null``).
    """
    deny = json.loads(raw)
    if not isinstance(deny, list):
        raise ValueError('LICENSE_DENY_LIST must be a JSON array')

    out: list[str] = []
    for x in deny:
        if isinstance(x, str):
            s = x.lower().strip()
            if s:
                out.append(s)

    return out


def _deny_from_thresholds(path: Path) -> list[str]:
    """Parse ``license_deny_list`` from a simple YAML thresholds file."""
    if not path.is_file():
        return []

    text = path.read_text(encoding='utf-8', errors='replace')
    # Match: license_deny_list: []  or  license_deny_list: ["GPL", "AGPL"]
    m = re.search(r'^license_deny_list:\s*(\[[^\]]*\])\s*(?:#.*)?$', text, flags=re.M)
    if not m:
        return []
    try:
        return _parse_deny_list(m.group(1))
    except (json.JSONDecodeError, ValueError):
        return []


def _resolve_deny_list() -> list[str]:
    """Env override wins; empty/``[]`` falls back to guardrails thresholds."""
    raw = os.environ.get('LICENSE_DENY_LIST', '').strip()
    if raw and raw != '[]':
        return _parse_deny_list(raw)

    thr = Path(
        os.environ.get(
            'THRESHOLDS_PATH',
            'docs/guardrails/supply-chain/profile.thresholds.yml',
        )
    )
    return _deny_from_thresholds(thr)


def _find_license_hits(packages: list[Any], deny_l: list[str]) -> list[str]:
    """Collect human-readable hit strings for packages matching any deny pattern."""
    hits: list[str] = []
    for pkg in packages:
        if not isinstance(pkg, dict):
            continue

        lic = pkg.get('licenseConcluded') or pkg.get('licenseDeclared') or ''
        if not lic or lic == 'NOASSERTION':
            continue

        lics = str(lic).lower()
        matched = [d for d in deny_l if d and d in lics]
        if matched:
            name = pkg.get('name', '?')
            pat = ', '.join(f"'{m}'" for m in matched)
            hits.append(f'{name}: {lic} (matched deny pattern(s) {pat})')

    return hits


def main() -> int:
    """Entry point: reads ``SPDX_SBOM_PATH`` and deny list from env or thresholds."""
    sbom = Path(os.environ.get('SPDX_SBOM_PATH', 'quality-output/sbom-spdx.json'))
    try:
        deny_l = _resolve_deny_list()
    except (json.JSONDecodeError, ValueError) as e:
        print(f'Invalid LICENSE_DENY_LIST: {e}', file=sys.stderr)
        return 2

    if not sbom.is_file():
        print(f'No SPDX SBOM at {sbom}; skipping license gate.')
        return 0

    try:
        data = json.loads(sbom.read_text(encoding='utf-8', errors='replace'))
    except json.JSONDecodeError as e:
        print(f'Invalid SPDX JSON at {sbom}: {e}', file=sys.stderr)
        return 3

    packages = data.get('packages', [])
    if not isinstance(packages, list):
        packages = []

    hits = _find_license_hits(packages, deny_l)
    if hits:
        print('Denied licenses detected in SPDX SBOM:', file=sys.stderr)
        for h in hits:
            print(f'  - {h}', file=sys.stderr)

        return 1

    return 0


if __name__ == '__main__':
    raise SystemExit(main())  # pragma: no cover
