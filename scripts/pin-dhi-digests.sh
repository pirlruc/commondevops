#!/usr/bin/env bash
# Pin Dockerfile FROM / COPY --from lines that reference dhi.io images to current digests.
# Requires: docker login dhi.io (Community DHI still needs Hub credentials).
#
# Usage:
#   bash scripts/pin-dhi-digests.sh [Dockerfile...]
# Env:
#   DHI_FROM_REFS — optional whitespace-separated image refs to refresh
#                   (default: all dhi.io/* refs found in the Dockerfiles)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mapfile -t FILES < <(
  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$@"
  else
    printf '%s\n' "${ROOT}/docker/ci-base/Dockerfile"
  fi
)

digest_for() {
  local ref="$1"
  docker buildx imagetools inspect "${ref}" --format '{{.Manifest.Digest}}'
}

refs_in_file() {
  local file="$1"
  grep -oE 'dhi\.io/[A-Za-z0-9._/-]+:[A-Za-z0-9._-]+' "${file}" | sort -u || true
}

declare -A DIGESTS=()

if [[ -n "${DHI_FROM_REFS:-}" ]]; then
  # shellcheck disable=SC2206
  forced=(${DHI_FROM_REFS})
  for ref in "${forced[@]}"; do
    DIGESTS["${ref}"]=pending
  done
else
  for file in "${FILES[@]}"; do
    [[ -f "${file}" ]] || { echo "missing ${file}" >&2; exit 1; }
    while IFS= read -r ref; do
      [[ -n "${ref}" ]] || continue
      DIGESTS["${ref}"]=pending
    done < <(refs_in_file "${file}")
  done
fi

if [[ ${#DIGESTS[@]} -eq 0 ]]; then
  echo "No dhi.io FROM refs found." >&2
  exit 1
fi

for ref in "${!DIGESTS[@]}"; do
  echo "Pulling ${ref} ..."
  docker pull "${ref}"
  dig="$(digest_for "${ref}")"
  [[ "${dig}" == sha256:* ]] || { echo "error: bad digest for ${ref}: ${dig}" >&2; exit 1; }
  DIGESTS["${ref}"]="${dig}"
  echo "  ${ref}@${dig}"
done

PINMAP="$(mktemp)"
trap 'rm -f "${PINMAP}"' EXIT
for ref in "${!DIGESTS[@]}"; do
  printf '%s\t%s\n' "${ref}" "${DIGESTS[${ref}]}" >> "${PINMAP}"
done

python3 - "${PINMAP}" "${FILES[@]}" <<'PY'
import pathlib
import re
import sys

pinmap_path = pathlib.Path(sys.argv[1])
files = [pathlib.Path(p) for p in sys.argv[2:]]
pins: dict[str, str] = {}
for line in pinmap_path.read_text(encoding="utf-8").splitlines():
    ref, dig = line.split("\t", 1)
    pins[ref] = dig

pat = re.compile(
    r"(?P<prefix>(?:FROM|COPY --from=))"
    r"(?P<ref>dhi\.io/[A-Za-z0-9._/-]+:[A-Za-z0-9._-]+)"
    r"(?:@sha256:[0-9a-f]+)?"
)

for path in files:
    text = path.read_text(encoding="utf-8")

    def repl(m: re.Match[str]) -> str:
        ref = m.group("ref")
        dig = pins.get(ref)
        if not dig:
            return m.group(0)
        return f"{m.group('prefix')}{ref}@{dig}"

    new, n = pat.subn(repl, text)
    if n == 0:
        print(f"warning: no dhi.io pins updated in {path}", file=sys.stderr)
    else:
        path.write_text(new, encoding="utf-8")
        print(f"Updated {n} pin(s) in {path}")
PY
