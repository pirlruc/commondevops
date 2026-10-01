# syntax=docker/dockerfile:1
# Org CI supply-chain image — SBOM / vuln / license CLIs for commondevops.
# Refresh digests: docker login dhi.io && bash scripts/pin-dhi-digests.sh docker/ci-supply-chain/Dockerfile
#
# Binary path discoveries (2026-08-10):
#   dhi.io/syft:1-debian13  → /usr/bin/syft
#   dhi.io/grype:0-debian13 → /usr/bin/grype
#   dhi.io/trivy:0-debian13 → /usr/bin/trivy
#   anchore/grant:v0.6.8    → /grant
#
# cosign is intentionally omitted: container-publish installs it on the runner
# via INSTALL_ONLY when sign=true (~109 MB saved).
#
# No HEALTHCHECK: short-lived CI toolchain (CLI job container), not a supervised
# service (DOCKER-RUN-002 / DOCKER-RUN-006).

# dhi.io/python:3.13-debian13-dev — digest pinned (DOCKER-BUILD-003 / CI-026)
FROM dhi.io/python:3.13-debian13-dev@sha256:cb32401c177600c7bacdb96a49ef51dd10d9967a868614288c428acc41e65604

LABEL org.opencontainers.image.title="ci-supply-chain" \
      org.opencontainers.image.description="Short-lived CI toolchain image for SBOM generation and vulnerability/license gates: syft, grype, trivy, grant. Non-root 1000:1000, linux/amd64." \
      org.opencontainers.image.source="https://github.com/pirlruc/commondevops" \
      org.opencontainers.image.url="https://hub.docker.com/r/pirlruc/ci-supply-chain" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/pirlruc/ci-supply-chain" \
      org.opencontainers.image.vendor="pirlruc" \
      org.opencontainers.image.licenses="MIT"

COPY --from=dhi.io/syft:1-debian13@sha256:592be9e9fb223f5bd3f175bba8f9191847b065cc97e03998cd3944c315b29128 \
  /usr/bin/syft /usr/local/bin/syft
COPY --from=dhi.io/grype:0-debian13@sha256:aa59b66b65c0cc54f094cd35614b203288477bc5d4d256be003b00a96a473925 \
  /usr/bin/grype /usr/local/bin/grype
COPY --from=dhi.io/trivy:0-debian13@sha256:db666d33cb95930e3932439e7a4c3678f480ea033b6bf1ffb6b7228d9e879d3d \
  /usr/bin/trivy /usr/local/bin/trivy
COPY --from=anchore/grant:v0.6.8@sha256:172463611795f43b77302cdfbd7b3f81295492a7330e0820cfe41c3674920237 \
  /grant /usr/local/bin/grant

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
USER 1000:1000

ENTRYPOINT []
CMD ["sh"]
