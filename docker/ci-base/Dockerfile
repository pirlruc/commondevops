# syntax=docker/dockerfile:1
# Org CI base image — DHI-first tool assembly for commondevops reusable workflows.
# Refresh digests: docker login dhi.io && bash scripts/pin-dhi-digests.sh docker/ci-base/Dockerfile
#
# Binary path discoveries (2026-08-10):
#   dhi.io/syft:1-debian13     → /usr/bin/syft
#   dhi.io/grype:0-debian13    → /usr/bin/grype
#   dhi.io/trivy:0-debian13    → /usr/bin/trivy
#   dhi.io/shellcheck:0-debian13 → /usr/local/bin/shellcheck
#   hadolint/hadolint:2.12.0-alpine → /bin/hadolint
#   rhysd/actionlint:1.7.7     → /usr/local/bin/actionlint
#   ghcr.io/astral-sh/uv:0.12.0 → /uv /uvx

# dhi.io/python:3.13-debian13-dev — digest pinned (DOCKER-BUILD-003)
FROM dhi.io/python:3.13-debian13-dev@sha256:5985b54ea3f145c9106890612792a0eb17c99e742e11fd9c391658f1946e1777

LABEL org.opencontainers.image.title="ci-base" \
      org.opencontainers.image.description="Shared CI tooling image for pirlruc/commondevops" \
      org.opencontainers.image.source="https://github.com/pirlruc/commondevops" \
      org.opencontainers.image.licenses="MIT"

# DHI supply-chain CLIs (distroless donors — COPY binaries only)
COPY --from=dhi.io/syft:1-debian13@sha256:3484ac184dd20f130a2f7b7ceb57b2e4f21a264338bb384295ea72bb825b2e3c \
  /usr/bin/syft /usr/local/bin/syft
COPY --from=dhi.io/grype:0-debian13@sha256:b5af85761b7c2cd5afbfc8e75ca3b23d6a706c14c3831966f2e25218ff2da23f \
  /usr/bin/grype /usr/local/bin/grype
COPY --from=dhi.io/trivy:0-debian13@sha256:f957a8173ddfc1e82cd4454fd760011e65cb03f42ffe67a91fe105a140ffade5 \
  /usr/bin/trivy /usr/local/bin/trivy
COPY --from=dhi.io/shellcheck:0-debian13@sha256:eb696ecbc0a6dbe57588d88c700c3da7cce3824f8c865795348f9b51c7524331 \
  /usr/local/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=dhi.io/cosign:2-debian13@sha256:44445adedd81bde6fee8645d4e23c36ffd62f4e6094a4d36c028b9efcd436be7 \
  /usr/bin/cosign /usr/local/bin/cosign
COPY --from=dhi.io/gitleaks:8-debian13@sha256:08b93b96ee818647ab1fb8e148bf8af4e1190b344e48b0e9bfa57eae98db8117 \
  /usr/local/bin/gitleaks /usr/local/bin/gitleaks

# Hub donors for workflow linters
COPY --from=hadolint/hadolint:2.12.0-alpine /bin/hadolint /usr/local/bin/hadolint
COPY --from=rhysd/actionlint:1.7.7 /usr/local/bin/actionlint /usr/local/bin/actionlint

# uv for Python tooling (zizmor, yamllint, semgrep)
COPY --from=ghcr.io/astral-sh/uv:0.12.0 /uv /uvx /usr/local/bin/

ENV PATH="/usr/local/bin:${PATH}" \
    UV_SYSTEM_PYTHON=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install Python CLIs into the DHI python image (dev variant has pip/uv-friendly layout).
RUN uv pip install --system --no-cache \
      'zizmor>=1.0' \
      'yamllint>=1.35' \
      'semgrep==1.159.0'

WORKDIR /workspace
ENTRYPOINT []
CMD ["bash"]
