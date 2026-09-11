#!/bin/sh
# Local CI parity for commondevops (CI-008).
# POSIX sh — the default ci-lint image is Alpine and has no bash.
#
# Host PATH tools preferred; missing tools deferred to check-ci-docker.sh.
# Step bodies live in ci-steps.sh (shared with the Docker path).
#
# Resolution table (host → Docker fallback via ci-lint):
# | Tool       | Host preferred | Docker fallback                         |
# |------------|----------------|-----------------------------------------|
# | actionlint | actionlint     | ci-lint:alpine-local (or COMMONDEVOPS_CI_IMAGE) |
# | shellcheck | shellcheck     | ci-lint:alpine-local                    |
# | hadolint   | hadolint       | ci-lint:alpine-local                    |
# | zizmor     | zizmor         | ci-lint:alpine-local                    |
# | yamllint   | yamllint       | ci-lint:alpine-local                    |
#
# Usage:
#   sh scripts/check-ci-local.sh
#   sh scripts/check-ci-local.sh --no-docker
set -eu

SCRIPT_DIR="$(dirname "$0")"
SCRIPT_DIR="$(cd "${SCRIPT_DIR}" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT}"

# shellcheck source=scripts/ci-steps.sh
. "${SCRIPT_DIR}/ci-steps.sh"

USE_DOCKER=1
for arg in "$@"; do
  if [ "${arg}" = "--no-docker" ]; then
    USE_DOCKER=0
  fi
done

DOCKER_STEPS=""
EXECUTED=""
MISSING=""

queue_docker() {
  name="$1"
  echo "→ ${name} missing on host; queue Docker"
  DOCKER_STEPS="${DOCKER_STEPS} ${name}"
  MISSING="${MISSING} ${name}"
}

run_or_queue() {
  name="$1"
  echo "==> ${name}"
  if command -v "${name}" >/dev/null 2>&1; then
    echo "→ ${name} (host)"
    dispatch_ci_step "${name}"
    EXECUTED="${EXECUTED} ${name}"
    return 0
  fi
  queue_docker "${name}"
}

run_or_queue actionlint
run_or_queue shellcheck
run_or_queue hadolint
run_or_queue zizmor
run_or_queue yamllint

echo "==> license_gate dry-run (no SBOM → skip with exit 0)"
python3 scripts/license_gate.py

if [ -n "${DOCKER_STEPS}" ]; then
  if [ "${USE_DOCKER}" = "1" ]; then
    # shellcheck disable=SC2086
    COMMONDEVOPS_DOCKER_STEPS="${DOCKER_STEPS}" sh "${SCRIPT_DIR}/check-ci-docker.sh"
  else
    echo "error: --no-docker set but tools missing on host:${MISSING}" >&2
    exit 1
  fi
fi

echo "Local CI parity finished. Host tools:${EXECUTED:- none}"
