# ci-supply-chain

Short-lived CI toolchain image for GitHub Actions jobs that generate SBOMs and
run vulnerability / license gates: syft, grype, trivy, and grant. Not a product
runtime — no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| Docker Hub | `pirlruc/ci-supply-chain` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |

### Tags

| Tag | Meaning |
|-----|---------|
| `5.2.0` / `5.2.0-alpine` | Immutable Alpine `sha256:f880c137677d703ec84ab0f386ceb0363d9e69aaf77bc3da40c0644dd7d9c784` |
| `5.2.0-debian` | Immutable Debian `sha256:b5f2c3feffb6b2e73d47f13e8bf286367a540f731a7513324592604d9683fa1b` |
| `5.1.0` / `5.1.0-alpine` | Previous Alpine `sha256:1bbe1ff600e0b1b9bb05e5f3acd512776bf65d48728a883dc074e6d52af10b07` |
| `5.1.0-debian` | Previous Debian `sha256:b2827c388dccbfdd60538d33bfe58df1fda356bfb39de31076291b67414c5d31` |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Alpine owns the unsuffixed tags because it currently has the lower OS vulnerability
posture on the DHI catalog. Prefer an explicit `-alpine` / `-debian` suffix when the
libc matters; prefer a digest in production.
`latest` equals `latest-alpine` (`flavor: latest=false`). A monthly rebuild may
move `latest` off the SemVer tag — pin the digest, not `latest`.

```bash
docker pull pirlruc/ci-supply-chain:5.2.0
docker pull pirlruc/ci-supply-chain:5.2.0-debian
docker pull pirlruc/ci-supply-chain@sha256:f880c137677d703ec84ab0f386ceb0363d9e69aaf77bc3da40c0644dd7d9c784
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-supply-chain:5.2.0 \
  syft . -o spdx-json
```

Hardened local run:

```bash
docker run --rm \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --tmpfs /tmp:rw,noexec,nosuid,size=256m \
  -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-supply-chain:5.2.0 \
  trivy fs --scanners vuln --severity HIGH,CRITICAL .
```

## What is inside

| Tool | Role |
|------|------|
| syft | SBOM generation |
| grype | Vulnerability scan from SBOM / image |
| trivy | Filesystem and image vulnerability scan |
| grant | License policy gate |

Not included: actionlint, hadolint, shellcheck, zizmor, yamllint, gitleaks,
semgrep (see `ci-lint`), cosign (installed on the publish runner), dive (see
`ci-container`).

## Verify a publish

```bash
docker pull pirlruc/ci-supply-chain@sha256:f880c137677d703ec84ab0f386ceb0363d9e69aaf77bc3da40c0644dd7d9c784

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  pirlruc/ci-supply-chain@sha256:f880c137677d703ec84ab0f386ceb0363d9e69aaf77bc3da40c0644dd7d9c784
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries embed dependency CVEs that only clear when upstream publishes
a newer digest. The publish gate uses `--pkg-types library`.

## License

MIT
