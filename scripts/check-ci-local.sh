#!/usr/bin/env bash
# Local CI parity for commondevops (CI-008).
# Host PATH tools preferred; missing tools deferred to check-ci-docker.sh.
#
# Resolution table (host → Docker fallback via ci-base):
# | Tool       | Host preferred | Docker fallback (ci-base / check-ci-docker) |
# |------------|----------------|---------------------------------------------|
# | actionlint | actionlint     | ghcr.io/pirlruc/ci-base:latest              |
# | shellcheck | shellcheck     | ghcr.io/pirlruc/ci-base:latest              |
# | hadolint   | hadolint       | ghcr.io/pirlruc/ci-base:latest              |
# | zizmor     | zizmor         | ghcr.io/pirlruc/ci-base:latest              |
# | yamllint   | yamllint       | ghcr.io/pirlruc/ci-base:latest              |
#
# Usage:
#   bash scripts/check-ci-local.sh
#   bash scripts/check-ci-local.sh --no-docker
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

USE_DOCKER=1
for arg in "$@"; do
  if [[ "${arg}" == "--no-docker" ]]; then
    USE_DOCKER=0
  fi
done

declare -a DOCKER_STEPS=()
declare -a EXECUTED=()

run_host() {
  local name="$1"
  shift
  if command -v "${name}" >/dev/null 2>&1; then
    echo "→ ${name} (host)"
    "$@"
    EXECUTED+=("${name}")
    return 0
  fi
  echo "→ ${name} missing on host; queue Docker"
  DOCKER_STEPS+=("${name}")
  return 0
}

echo "==> actionlint"
# shellcheck disable=SC2016  # intentional: run_host body must not expand on the host
run_host actionlint bash -c '
  mapfile -t WFS < <(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -40)
  if [[ ${#WFS[@]} -eq 0 ]]; then
    echo "No workflows to lint"
    exit 0
  fi
  actionlint "${WFS[@]}"
'

echo "==> shellcheck"
# shellcheck disable=SC2016  # intentional: run_host body must not expand on the host
run_host shellcheck bash -c '
  mapfile -t SHS < <(find scripts -name "*.sh" 2>/dev/null)
  if [[ ${#SHS[@]} -eq 0 ]]; then
    echo "No shell scripts"
    exit 0
  fi
  shellcheck "${SHS[@]}"
'

echo "==> hadolint"
run_host hadolint hadolint docker/ci-base/Dockerfile

echo "==> zizmor"
run_host zizmor zizmor .github/workflows

echo "==> license_gate dry-run (no SBOM → skip)"
python3 scripts/license_gate.py || true

if ((${#DOCKER_STEPS[@]} > 0)); then
  if [[ "${USE_DOCKER}" == "1" ]]; then
    COMMONDEVOPS_DOCKER_STEPS="${DOCKER_STEPS[*]}" bash "${ROOT}/scripts/check-ci-docker.sh"
  else
    echo "Skipped Docker fallback (--no-docker). Missing: ${DOCKER_STEPS[*]}"
  fi
fi

echo "Local CI parity finished. Host tools: ${EXECUTED[*]:-none}"
