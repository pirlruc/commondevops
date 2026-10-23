# syntax=docker/dockerfile:1
# Org CI image for OpenTofu, tflint, sops, age, and ansible-lint.
# These tools stay off ci-lint. ci-lint remains workflow lint plus secrets/SAST.
#
# No HEALTHCHECK: short-lived CI toolchain (CLI job container), not a supervised
# service (DOCKER-RUN-002 / DOCKER-RUN-006).
#
# age and sops are rebuilt on Go 1.26.10. OpenTofu 1.13.2 requires Go 1.27.3,
# so that stage sets GOTOOLCHAIN. tflint 0.65.0 stays the upstream release.

FROM dhi.io/golang:1.27-debian13-dev@sha256:4bbc77c673289765ba1facc2cc56678cd8d613db25a123b7e2ecc1315a53620a AS age-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/FiloSottile/age.git \
 && git fetch --depth 1 origin b74dce4cdbe35b5e5f66c06d9612b72f89028758 \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "b74dce4cdbe35b5e5f66c06d9612b72f89028758" \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/age ./cmd/age \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/age-keygen ./cmd/age-keygen

FROM dhi.io/golang:1.27-debian13-dev@sha256:4bbc77c673289765ba1facc2cc56678cd8d613db25a123b7e2ecc1315a53620a AS sops-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/getsops/sops.git \
 && git fetch --depth 1 origin 26e2f4784ca61353082c32dbd987c25eda086dc9 \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "26e2f4784ca61353082c32dbd987c25eda086dc9" \
 && go get golang.org/x/crypto@v0.57.0 golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0 google.golang.org/grpc@v1.83.2 \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/sops ./cmd/sops

FROM dhi.io/golang:1.27-debian13-dev@sha256:4bbc77c673289765ba1facc2cc56678cd8d613db25a123b7e2ecc1315a53620a AS tofu-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/opentofu/opentofu.git \
 && git fetch --depth 1 origin 765062032c46cacab116b36d714db098b806dede \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "765062032c46cacab116b36d714db098b806dede" \
 && GOTOOLCHAIN=go1.27.3 go get golang.org/x/crypto@v0.57.0 golang.org/x/mod@v0.41.0 golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0 google.golang.org/grpc@v1.83.2 \
 && CGO_ENABLED=0 GOTOOLCHAIN=go1.27.3 go build -trimpath -ldflags="-s -w" -o /out/tofu ./cmd/tofu

FROM dhi.io/python:3.13-debian13-dev@sha256:e06c1af7512805e1822259b7e9fe6ab27462a09c71c9520bc47b5c5388e3fce6 AS fetch
USER root
RUN python3 - <<'PY'
import hashlib
import urllib.request
import zipfile
from pathlib import Path

out = Path("/out")
out.mkdir(parents=True, exist_ok=True)
dest = Path("/tmp/tflint.zip")
urllib.request.urlretrieve(
    "https://github.com/terraform-linters/tflint/releases/download/v0.65.0/tflint_linux_amd64.zip",
    dest,
)
digest = hashlib.sha256(dest.read_bytes()).hexdigest()
if digest != "d4c545ed2e29d6338604b586f34f544f380f70f243aa72f7b484713835eaec61":
    raise SystemExit(f"checksum mismatch for tflint: {digest}")
with zipfile.ZipFile(dest) as archive:
    archive.extract("tflint", "/tmp/tflint-src")
target = out / "tflint"
target.write_bytes(Path("/tmp/tflint-src/tflint").read_bytes())
target.chmod(0o755)
PY

USER 1000

FROM dhi.io/python:3.13-debian13-dev@sha256:e06c1af7512805e1822259b7e9fe6ab27462a09c71c9520bc47b5c5388e3fce6 AS pybuild
COPY --from=ghcr.io/astral-sh/uv:0.12.0@sha256:606e70c71c852d03f611b1e56a195d08648507018a7057fab82c4974c4eae105 \
  /uv /usr/local/bin/uv
ENV UV_SYSTEM_PYTHON=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache --require-hashes -r /tmp/requirements.txt \
 && rm -f /tmp/requirements.txt

FROM dhi.io/python:3.13-debian13-dev@sha256:e06c1af7512805e1822259b7e9fe6ab27462a09c71c9520bc47b5c5388e3fce6

LABEL org.opencontainers.image.title="ci-iac" \
      org.opencontainers.image.description="Short-lived CI image for OpenTofu, tflint, sops, age, and ansible-lint. Non-root 1000:1000, linux/amd64." \
      org.opencontainers.image.source="https://github.com/pirlruc/commondevops" \
      org.opencontainers.image.url="https://hub.docker.com/r/pirlruc/ci-iac" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/pirlruc/ci-iac" \
      org.opencontainers.image.vendor="pirlruc" \
      org.opencontainers.image.licenses="MIT"

COPY --from=tofu-build /out/tofu /usr/local/bin/tofu
COPY --from=fetch /out/tflint /usr/local/bin/tflint
COPY --from=sops-build /out/sops /usr/local/bin/sops
COPY --from=age-build /out/age /out/age-keygen /usr/local/bin/
COPY --from=pybuild /usr/lib/python3.13/site-packages /usr/lib/python3.13/site-packages
COPY --from=pybuild \
  /usr/bin/ansible-lint \
  /usr/bin/ansible \
  /usr/bin/ansible-config \
  /usr/bin/ansible-galaxy \
  /usr/bin/ansible-inventory \
  /usr/bin/ansible-playbook \
  /usr/bin/ansible-vault \
  /usr/bin/

ENV PATH="/usr/local/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

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

RUN printf 'ci:x:1000:1000::/home/ci:/bin/sh\n' >> /etc/passwd \
 && printf 'ci:x:1000:\n' >> /etc/group \
 && mkdir -p /home/ci \
 && chown -R 1000:1000 /home/ci /workspace
RUN find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod a-s {} +
USER 1000:1000

ENTRYPOINT []
CMD ["sh"]
