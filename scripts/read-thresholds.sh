#!/usr/bin/env bash
# Read a threshold key from a YAML profile (vendored or guardrails submodule).
set -euo pipefail
KEY="${1:?threshold key required}"
FILE="${2:-scripts/supply-chain.profile.thresholds.yml}"
if [[ ! -f "${FILE}" ]]; then
  echo "Missing ${FILE}; vendor or pass an explicit thresholds path." >&2
  exit 1
fi
# Strip inline comments after the value
grep "^${KEY}:" "${FILE}" | head -1 | awk '{print $2}' | tr -d '\r'
