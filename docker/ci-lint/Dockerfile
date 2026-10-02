# syntax=docker/dockerfile:1
# Org CI lint image — workflow linters + secrets/SAST CLIs for commondevops.
# Refresh digests: docker login dhi.io && bash scripts/pin-dhi-digests.sh docker/ci-lint/Dockerfile
#
# Binary path discoveries (2026-08-10):
#   dhi.io/shellcheck:0-debian13 → /usr/local/bin/shellcheck
#   dhi.io/gitleaks:8-debian13   → /usr/bin/gitleaks
#   hadolint/hadolint:v2.15.1-alpine → /bin/hadolint
#   actionlint v1.7.12 is rebuilt in-image on Go 1.26.8 (commit 914e7df2)
#   ghcr.io/astral-sh/uv:0.12.0  → /uv (build stage only)
#
# No HEALTHCHECK: short-lived CI toolchain (CLI job container), not a supervised
# service (DOCKER-RUN-002 / DOCKER-RUN-006).

# actionlint v1.7.12 rebuilt with Go 1.26.8. Stdlib fixes only; modules stay
# at the upstream go.sum (CMN-CVE-001).
FROM dhi.io/golang:1.26-debian13-dev@sha256:06dc5566a36380eb27e0eef948ce336fe53790617fd8512a1d21b1d774c0545a AS actionlint-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/rhysd/actionlint.git \
 && git fetch --depth 1 origin 914e7df21a07ef503a81201c76d2b11c789d3fca \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "914e7df21a07ef503a81201c76d2b11c789d3fca" \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/actionlint ./cmd/actionlint

# ---------------------------------------------------------------------------
# pybuild — install Python CLIs; uv stays out of the final image (~53 MB).
# ---------------------------------------------------------------------------
FROM dhi.io/python:3.13-debian13-dev@sha256:cb32401c177600c7bacdb96a49ef51dd10d9967a868614288c428acc41e65604 AS pybuild
COPY --from=ghcr.io/astral-sh/uv:0.12.0@sha256:606e70c71c852d03f611b1e56a195d08648507018a7057fab82c4974c4eae105 \
  /uv /usr/local/bin/uv
ENV UV_SYSTEM_PYTHON=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
# semgrep 1.179.0 requires PyJWT>=2.15 and pins mcp==1.29.0.
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache --require-hashes -r /tmp/requirements.txt \
 && rm -f /tmp/requirements.txt

# ---------------------------------------------------------------------------
# Final image
# ---------------------------------------------------------------------------
FROM dhi.io/python:3.13-debian13-dev@sha256:cb32401c177600c7bacdb96a49ef51dd10d9967a868614288c428acc41e65604

LABEL org.opencontainers.image.title="ci-lint" \
      org.opencontainers.image.description="Short-lived CI toolchain image for lint and secrets/SAST: actionlint, hadolint, shellcheck, zizmor, yamllint, gitleaks, semgrep. Non-root 1000:1000, linux/amd64." \
      org.opencontainers.image.source="https://github.com/pirlruc/commondevops" \
      org.opencontainers.image.url="https://hub.docker.com/r/pirlruc/ci-lint" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/pirlruc/ci-lint" \
      org.opencontainers.image.vendor="pirlruc" \
      org.opencontainers.image.licenses="MIT"

COPY --from=dhi.io/shellcheck:0-debian13@sha256:eb696ecbc0a6dbe57588d88c700c3da7cce3824f8c865795348f9b51c7524331 \
  /usr/local/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=dhi.io/gitleaks:8-debian13@sha256:7f7f90449d80971451a7fc20eedd1875b7271ef68be571b1b9550f19109c32c3 \
  /usr/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=hadolint/hadolint:v2.15.1-alpine@sha256:a1d49ae1a4e83c1dbad26b8c1ad7588c8bd1e04f4866b34ad3cac50335198552 \
  /bin/hadolint /usr/local/bin/hadolint
COPY --from=actionlint-build /out/actionlint /usr/local/bin/actionlint

# Python packages + console scripts from pybuild (no uv binary in final).
COPY --from=pybuild /usr/lib/python3.13/site-packages /usr/lib/python3.13/site-packages
COPY --from=pybuild /usr/bin/semgrep /usr/bin/pysemgrep /usr/bin/zizmor /usr/bin/yamllint /usr/bin/

ENV PATH="/usr/local/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Drop build-only headers/dev packages and the DHI status.d stubs that apt-get
# purge leaves behind (Trivy otherwise reports phantom linux-libc-dev CVEs).
USER root
RUN set -eu; \
    for p in linux-libc-dev libc6-dev libexpat1-dev libpython-3.13-dev \
             python-3.13-dev zlib1g-dev rpcsvc-proto; do \
      if dpkg-query -W "$p" >/dev/null 2>&1; then \
        apt-get purge -y --auto-remove "$p"; \
      fi; \
      rm -f "/var/lib/dpkg/status.d/${p}" "/var/lib/dpkg/status.d/${p}.md5sums"; \
    done; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

WORKDIR /workspace

# Non-root default user. DHI images have no useradd; write passwd/group directly.
# Login shell is /bin/sh so the same CMD works on Debian and Alpine variants.
RUN printf 'ci:x:1000:1000::/home/ci:/bin/sh\n' >> /etc/passwd \
 && printf 'ci:x:1000:\n' >> /etc/group \
 && mkdir -p /home/ci \
 && chown -R 1000:1000 /home/ci /workspace
RUN find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod a-s {} +
USER 1000:1000

ENTRYPOINT []
CMD ["sh"]
