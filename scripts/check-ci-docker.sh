#!/usr/bin/env bash
# Run CI steps that are missing on the host inside ghcr.io/pirlruc/ci-lint:latest
# (or a locally built docker/ci-lint image).
#
# Env:
#   COMMONDEVOPS_CI_IMAGE — image ref (default ghcr.io/pirlruc/ci-lint:latest)
#   COMMONDEVOPS_DOCKER_STEPS — space-separated step names (required)
#   COMMONDEVOPS_BUILD_LOCAL — if 1, build docker/ci-lint when pull fails
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${COMMONDEVOPS_CI_IMAGE:-ghcr.io/pirlruc/ci-lint:latest}"
BUILD_LOCAL="${COMMONDEVOPS_BUILD_LOCAL:-1}"
ADVISORY="${COMMONDEVOPS_ADVISORY:-0}"

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
      echo "==> Pull failed; building local docker/ci-lint as ${IMAGE}"
      docker build -t "${IMAGE}" -f "${ROOT}/docker/ci-lint/Dockerfile" "${ROOT}/docker/ci-lint"
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
  -e "COMMONDEVOPS_ADVISORY=${ADVISORY}" \
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
          mapfile -t DFS < <(find docker -name 'Dockerfile*' 2>/dev/null)
          hadolint "${DFS[@]}"
          ;;
        zizmor)
          zizmor --min-severity=low .github/workflows
          ;;
        yamllint)
          set +e
          yamllint -d relaxed .github/workflows docs
          yc=$?
          set -e
          if (( yc != 0 )); then
            if [[ "${COMMONDEVOPS_ADVISORY}" == "1" ]]; then
              echo "yamllint findings (advisory — continuing)"
            else
              echo "yamllint findings (blocking). Set COMMONDEVOPS_ADVISORY=1 to continue." >&2
              exit "${yc}"
            fi
          fi
          ;;
        *)
          echo "Unknown step: ${step}" >&2
          exit 2
          ;;
      esac
    done
  '
