#!/bin/sh
# Run CI steps that are missing on the host inside the ci-lint image.
# POSIX sh — Alpine ci-lint has no bash (CI-036 / CMN-WF-003-T1).
#
# Env:
#   COMMONDEVOPS_CI_IMAGE     — ci-lint image (default digest-pinned 5.1.1 Alpine)
#   COMMONDEVOPS_DOCKER_STEPS — space-separated step names (required)
#   COMMONDEVOPS_BUILD_LOCAL  — if 1, build docker/ci-lint when pull fails (tag refs only)
#   COMMONDEVOPS_ADVISORY     — if 1, yamllint findings are non-blocking
#
# Usage:
#   COMMONDEVOPS_DOCKER_STEPS="actionlint shellcheck" sh scripts/check-ci-docker.sh
#   COMMONDEVOPS_CI_IMAGE=ci-lint:alpine-local COMMONDEVOPS_DOCKER_STEPS="shellcheck" \
#     sh scripts/check-ci-docker.sh
set -eu

SCRIPT_DIR="$(dirname "$0")"
SCRIPT_DIR="$(cd "${SCRIPT_DIR}" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# CI-026 / DOCKER-SEC-006 — digest pin; tag is documentation only.
IMAGE="${COMMONDEVOPS_CI_IMAGE:-ghcr.io/pirlruc/ci-lint:5.2.0@sha256:33dbcc7be28ffef2a6cf3cf4b611cf862a8f246c6d6932c4055772d73d697674}"
BUILD_LOCAL="${COMMONDEVOPS_BUILD_LOCAL:-1}"
ADVISORY="${COMMONDEVOPS_ADVISORY:-0}"

if [ -z "${COMMONDEVOPS_DOCKER_STEPS:-}" ]; then
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

ensure_image() {
  img="$1"
  if docker image inspect "${img}" >/dev/null 2>&1; then
    return 0
  fi
  echo "==> Pulling ${img}"
  if docker pull "${img}"; then
    return 0
  fi
  case "${img}" in
    *@*)
      echo "error: cannot pull digest-pinned ${img}" >&2
      echo "Set COMMONDEVOPS_CI_IMAGE to a local tag (e.g. ci-lint:alpine-local):" >&2
      echo "  docker build -t ci-lint:alpine-local -f docker/ci-lint/Dockerfile.alpine docker/ci-lint" >&2
      exit 1
      ;;
  esac
  if [ "${BUILD_LOCAL}" = "1" ]; then
    echo "==> Pull failed; building local docker/ci-lint as ${img}"
    docker build -t "${img}" -f "${ROOT}/docker/ci-lint/Dockerfile.alpine" "${ROOT}/docker/ci-lint"
    return 0
  fi
  echo "error: cannot pull ${img} and COMMONDEVOPS_BUILD_LOCAL!=1" >&2
  exit 1
}

ensure_image "${IMAGE}"

echo "==> Running in Docker (${IMAGE}): ${COMMONDEVOPS_DOCKER_STEPS}"
docker run --rm \
  -v "${ROOT}:/workspace:ro" \
  -w /workspace \
  -e "COMMONDEVOPS_DOCKER_STEPS=${COMMONDEVOPS_DOCKER_STEPS}" \
  -e "COMMONDEVOPS_ADVISORY=${ADVISORY}" \
  "${IMAGE}" \
  sh -c '
    set -eu
    # shellcheck source=scripts/ci-steps.sh
    . ./scripts/ci-steps.sh
    for step in ${COMMONDEVOPS_DOCKER_STEPS}; do
      echo "==> ${step}"
      dispatch_ci_step "${step}"
    done
  '
