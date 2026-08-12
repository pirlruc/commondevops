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
| `3.0.0` / `3.0.0-alpine` | Immutable Alpine release (default unsuffixed = Alpine) |
| `3.0.0-debian` | Immutable Debian 13 release |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Alpine owns the unsuffixed tags because it currently has the lower OS vulnerability
posture on the DHI catalog. Prefer an explicit `-alpine` / `-debian` suffix when the
libc matters; prefer a digest in production.

```bash
docker pull pirlruc/ci-supply-chain:3.0.0
docker pull pirlruc/ci-supply-chain:3.0.0-debian
# or
docker pull pirlruc/ci-supply-chain@sha256:<digest>
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-supply-chain:3.0.0 \
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
  pirlruc/ci-supply-chain:3.0.0 \
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
docker pull pirlruc/ci-supply-chain@sha256:<digest>

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  pirlruc/ci-supply-chain@sha256:<digest>
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries embed dependency CVEs that only clear when upstream publishes
a newer digest. The publish gate uses `--pkg-types library`.

## License

MIT
