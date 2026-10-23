# syntax=docker/dockerfile:1
# Org CI supply-chain image — SBOM / vuln / license CLIs for commondevops.
# Refresh digests: docker login dhi.io && bash scripts/pin-dhi-digests.sh docker/ci-supply-chain/Dockerfile
#
# Binary path discoveries (2026-08-10):
#   syft 1.50.0, grype 0.116.1, trivy 0.71.2, and grant 0.6.8 are rebuilt
#   in-image on Go 1.26.10. Donor images were still Go 1.26.8.
#
# cosign is intentionally omitted: container-publish installs it on the runner
# via INSTALL_ONLY when sign=true (~109 MB saved).
#
# No HEALTHCHECK: short-lived CI toolchain (CLI job container), not a supervised
# service (DOCKER-RUN-002 / DOCKER-RUN-006).

# grant v0.6.8 rebuilt with Go 1.26.10. Stdlib fixes only; modules stay at go.sum.
FROM dhi.io/golang:1.26-debian13-dev@sha256:5bff7bbb70c4f0791e039b58deb70eb0609dcc2d503c5524af3565b86d8b7544 AS grant-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/anchore/grant.git \
 && git fetch --depth 1 origin 0fb3c502202139efcf4a20aa72014cf6eafab930 \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "0fb3c502202139efcf4a20aa72014cf6eafab930" \
 && go get golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0 github.com/klauspost/compress@v1.18.7 github.com/containerd/containerd/v2@v2.3.4 github.com/go-git/go-git/v5@v5.19.2 google.golang.org/grpc@v1.83.2 \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/grant ./cmd/grant

# syft 1.50.0 (16223e6d), grype 0.116.1 (30394f17), trivy 0.71.2 (055a5c8a).
FROM dhi.io/golang:1.26-debian13-dev@sha256:5bff7bbb70c4f0791e039b58deb70eb0609dcc2d503c5524af3565b86d8b7544 AS syft-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/anchore/syft.git \
 && git fetch --depth 1 origin 16223e6dd7893fe578787658ceb876257483d404 \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "16223e6dd7893fe578787658ceb876257483d404" \
 && go get golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0 github.com/containerd/containerd/v2@v2.3.4 github.com/go-git/go-git/v5@v5.19.2 google.golang.org/grpc@v1.83.2 \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/syft ./cmd/syft

FROM dhi.io/golang:1.26-debian13-dev@sha256:5bff7bbb70c4f0791e039b58deb70eb0609dcc2d503c5524af3565b86d8b7544 AS grype-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/anchore/grype.git \
 && git fetch --depth 1 origin 30394f177175da63ae36b35cdd809c248eb4de7f \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "30394f177175da63ae36b35cdd809c248eb4de7f" \
 && go get golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0 github.com/anchore/syft@v1.50.0 github.com/containerd/containerd/v2@v2.3.4 github.com/go-git/go-git/v5@v5.19.2 google.golang.org/grpc@v1.83.2 \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/grype ./cmd/grype

FROM dhi.io/golang:1.26-debian13-dev@sha256:5bff7bbb70c4f0791e039b58deb70eb0609dcc2d503c5524af3565b86d8b7544 AS trivy-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/aquasecurity/trivy.git \
 && git fetch --depth 1 origin 055a5c8a53bfd61f7a8e276a5b2f0c3fc1673420 \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "055a5c8a53bfd61f7a8e276a5b2f0c3fc1673420" \
 && go get golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0 github.com/klauspost/compress@v1.18.7 github.com/containerd/containerd/v2@v2.3.4 github.com/go-git/go-git/v5@v5.19.2 google.golang.org/grpc@v1.83.2 oras.land/oras-go/v2@v2.6.2 \
 && CGO_ENABLED=0 GOEXPERIMENT=jsonv2 go build -trimpath -ldflags="-s -w" -o /out/trivy ./cmd/trivy

# dhi.io/python:3.13-debian13-dev — digest pinned (DOCKER-BUILD-003 / CI-026)
FROM dhi.io/python:3.13-debian13-dev@sha256:cb32401c177600c7bacdb96a49ef51dd10d9967a868614288c428acc41e65604

LABEL org.opencontainers.image.title="ci-supply-chain" \
      org.opencontainers.image.description="Short-lived CI toolchain image for SBOM generation and vulnerability/license gates: syft, grype, trivy, grant. Non-root 1000:1000, linux/amd64." \
      org.opencontainers.image.source="https://github.com/pirlruc/commondevops" \
      org.opencontainers.image.url="https://hub.docker.com/r/pirlruc/ci-supply-chain" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/pirlruc/ci-supply-chain" \
      org.opencontainers.image.vendor="pirlruc" \
      org.opencontainers.image.licenses="MIT"

COPY --from=syft-build /out/syft /usr/local/bin/syft
COPY --from=grype-build /out/grype /usr/local/bin/grype
COPY --from=trivy-build /out/trivy /usr/local/bin/trivy
COPY --from=grant-build /out/grant /usr/local/bin/grant

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
