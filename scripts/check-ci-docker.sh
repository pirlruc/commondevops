#!/usr/bin/env bash
# Run CI steps that are missing on the host inside ghcr.io/pirlruc/ci-base:latest
# (or a locally built docker/ci-base image).
#
# Env:
#   COMMONDEVOPS_CI_IMAGE — image ref (default ghcr.io/pirlruc/ci-base:latest)
#   COMMONDEVOPS_DOCKER_STEPS — space-separated step names (required)
#   COMMONDEVOPS_BUILD_LOCAL — if 1, build docker/ci-base when pull fails
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${COMMONDEVOPS_CI_IMAGE:-ghcr.io/pirlruc/ci-base:latest}"
BUILD_LOCAL="${COMMONDEVOPS_BUILD_LOCAL:-1}"

if [[ -z "${COMMONDEVOPS_DOCKER_STEPS:-}" ]]; then
  echo "COMMONDEVOPS_DOCKER_STEPS is required (e.g. actionlint shellcheck hadolint zizmor)" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required for host-unavailable CI checks" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker engine is not running" >&2
  exit 1
fi

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "==> Pulling ${IMAGE}"
  if ! docker pull "${IMAGE}"; then
    if [[ "${BUILD_LOCAL}" == "1" ]]; then
      echo "==> Pull failed; building local docker/ci-base as ${IMAGE}"
      docker build -t "${IMAGE}" -f "${ROOT}/docker/ci-base/Dockerfile" "${ROOT}/docker/ci-base"
    else
      echo "error: cannot pull ${IMAGE} and COMMONDEVOPS_BUILD_LOCAL!=1" >&2
      exit 1
    fi
  fi
fi

echo "==> Running in Docker (${IMAGE}): ${COMMONDEVOPS_DOCKER_STEPS}"
docker run --rm \
  -v "${ROOT}:/workspace:ro" \
  -w /workspace \
  -e "COMMONDEVOPS_DOCKER_STEPS=${COMMONDEVOPS_DOCKER_STEPS}" \
  "${IMAGE}" \
  bash -lc '
    set -euo pipefail
    for step in ${COMMONDEVOPS_DOCKER_STEPS}; do
      echo "==> ${step}"
      case "${step}" in
        actionlint)
          mapfile -t WFS < <(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -40)
          actionlint "${WFS[@]}"
          ;;
        shellcheck)
          mapfile -t SHS < <(find scripts -name "*.sh" 2>/dev/null)
          shellcheck "${SHS[@]}"
          ;;
        hadolint)
          hadolint docker/ci-base/Dockerfile
          ;;
        zizmor)
          zizmor .github/workflows
          ;;
        yamllint)
          yamllint -d relaxed .github/workflows docs || true
          ;;
        *)
          echo "Unknown step: ${step}" >&2
          exit 2
          ;;
      esac
    done
  '
