# Docker Hub — ci-lint

Public overview for the [pirlruc/ci-lint](https://hub.docker.com/r/pirlruc/ci-lint)
image (also published to `ghcr.io/pirlruc/ci-lint`). Paste or adapt this page into
the Docker Hub **Overview**.

**ci-lint** is a short-lived CI toolchain image for GitHub Actions jobs that run
workflow lint and secrets/SAST: actionlint, hadolint, shellcheck, zizmor,
yamllint, gitleaks, and semgrep. It is not a product runtime and has no
`HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| Docker Hub | `pirlruc/ci-lint` |
| GHCR | `ghcr.io/pirlruc/ci-lint` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |

### Tags

| Tag | Meaning |
|-----|---------|
| `2.0.0` | Immutable release (example; prefer the current semver) |
| `2.0` | Latest patch in the `2.0` line |
| `latest` | Latest non-prerelease publish |
| `sha-<git>` | Exact git SHA of the published commit |

Prefer a version tag or digest in production.

```bash
docker pull pirlruc/ci-lint:2.0.0
# or
docker pull ghcr.io/pirlruc/ci-lint@sha256:<digest>
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-lint:2.0.0 \
  actionlint .github/workflows/*.yml
```

Hardened local run (read-only workspace mount):

```bash
docker run --rm \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --tmpfs /tmp:rw,noexec,nosuid,size=256m \
  -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-lint:2.0.0 \
  semgrep scan --config auto --error .
```

## What is inside

| Tool | Role |
|------|------|
| actionlint | GitHub Actions workflow lint |
| hadolint | Dockerfile lint |
| shellcheck | Shell script lint |
| zizmor | Actions security lint |
| yamllint | YAML lint |
| gitleaks | Secrets detection |
| semgrep | SAST (`--config auto`) |

Not included: syft, grype, trivy, grant, cosign, dive (see `ci-supply-chain`
and `ci-container`).

## Vulnerabilities

Donor Go binaries (notably actionlint) embed stdlib CVEs that only clear when
upstream publishes a newer digest. Path-scoped Trivy ignores are maintained in
the source repo under `docker/ci-lint/.trivyignore.yaml` with a review date.
OS packages without upstream fixes may still appear in a full `os,library`
scan; the publish gate uses `--pkg-types library`.

## Source and support

- Source: https://github.com/pirlruc/commondevops
- Releases: https://github.com/pirlruc/commondevops/releases
- License: MIT
