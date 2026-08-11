# Docker Hub — ci-supply-chain

Public overview for the
[pirlruc/ci-supply-chain](https://hub.docker.com/r/pirlruc/ci-supply-chain)
image (also published to `ghcr.io/pirlruc/ci-supply-chain`). Paste or adapt this
page into the Docker Hub **Overview**.

**ci-supply-chain** is a short-lived CI toolchain image for GitHub Actions jobs
that generate SBOMs and run vulnerability / license gates: syft, grype, trivy,
and grant. It is not a product runtime and has no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| Docker Hub | `pirlruc/ci-supply-chain` |
| GHCR | `ghcr.io/pirlruc/ci-supply-chain` |
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
docker pull pirlruc/ci-supply-chain:2.0.0
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-supply-chain:2.0.0 \
  syft dir:. -o spdx-json=sbom.spdx.json
```

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  pirlruc/ci-supply-chain:2.0.0 \
  trivy image --severity HIGH,CRITICAL --pkg-types library my-app:local
```

## What is inside

| Tool | Role |
|------|------|
| syft | SBOM generation (CycloneDX / SPDX) |
| grype | Vulnerability scan (often against an SBOM) |
| trivy | Vulnerability scan (filesystem or image) |
| grant | License allow-list gate |

Not included: actionlint, hadolint, shellcheck, semgrep, gitleaks (see
`ci-lint`), cosign (install on the publish runner), dive / structure-test
(see `ci-container`).

## Vulnerabilities

Donor Go binaries embed dependency CVEs that only clear when upstream publishes
a newer digest. Path-scoped Trivy ignores live under
`docker/ci-supply-chain/.trivyignore.yaml` with a review date. The publish gate
uses `--pkg-types library`; a full `os,library` scan may still report OS
packages without upstream fixes.

## Source and support

- Source: https://github.com/pirlruc/commondevops
- Releases: https://github.com/pirlruc/commondevops/releases
- License: MIT
