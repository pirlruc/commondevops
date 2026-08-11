# ci-supply-chain (GitHub Packages)

Short-lived CI toolchain image for GitHub Actions jobs that generate SBOMs and
run vulnerability / license gates: syft, grype, trivy, and grant. Not a product
runtime — no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| GHCR | `ghcr.io/pirlruc/ci-supply-chain` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |

### Tags

| Tag | Meaning |
|-----|---------|
| `2.0.1` | Immutable release (prefer the current semver) |
| `2.0` | Latest patch in the `2.0` line |
| `latest` | Latest non-prerelease publish |
| `sha-<git>` | Exact git SHA of the published commit |

Prefer a version tag or digest in production.

## Authentication

If the package is public, anonymous pulls work:

```bash
docker pull ghcr.io/pirlruc/ci-supply-chain:2.0.1
```

If the package is private, authenticate with a PAT that has `read:packages`:

```bash
echo "$CR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/pirlruc/ci-supply-chain:2.0.1
# or
docker pull ghcr.io/pirlruc/ci-supply-chain@sha256:<digest>
```

## Use as a GitHub Actions job container

```yaml
jobs:
  supply-chain:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/pirlruc/ci-supply-chain:2.0.1
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - run: syft . -o spdx-json
```

Grant the package **Actions** Read access for the calling repository when using
`GITHUB_TOKEN`, or pass a PAT with `read:packages`.

## Quick start (local)

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  ghcr.io/pirlruc/ci-supply-chain:2.0.1 \
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
  ghcr.io/pirlruc/ci-supply-chain:2.0.1 \
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
docker pull ghcr.io/pirlruc/ci-supply-chain@sha256:<digest>

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/pirlruc/ci-supply-chain@sha256:<digest>
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries embed dependency CVEs that only clear when upstream publishes
a newer digest. The publish gate uses `--pkg-types library`.

## License

MIT
