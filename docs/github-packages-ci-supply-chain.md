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
| `5.2.4` / `5.2.4-alpine` | Immutable Alpine `sha256:f7abb77fd31aeb68bf31ff391ed0e54825f706314607dc1570088e19d3d6c55c` |
| `5.2.4-debian` | Immutable Debian `sha256:99aa0689b82930919e525e2f6afdbfde5819bb1ab587e2fd2be20022a0f204fc` |
| `5.2.2` / `5.2.2-alpine` | Previous Alpine `sha256:2ea8da1b95fd393e8b2897fb0d11eba97d9036d9df011519bed058df172a9257` |
| `5.2.2-debian` | Previous Debian `sha256:8c8235b4c116be68915c08c5518b8e9f26d4b60fd8ed8b70a9653afcc2999623` |
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

## Authentication

If the package is public, anonymous pulls work:

```bash
docker pull ghcr.io/pirlruc/ci-supply-chain:5.2.4
```

If the package is private, authenticate with a PAT that has `read:packages`:

```bash
echo "$CR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/pirlruc/ci-supply-chain:5.2.4
# or
docker pull ghcr.io/pirlruc/ci-supply-chain@sha256:f7abb77fd31aeb68bf31ff391ed0e54825f706314607dc1570088e19d3d6c55c
```

## Use as a GitHub Actions job container

```yaml
jobs:
  supply-chain:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/pirlruc/ci-supply-chain:5.2.4
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - run: syft . -o spdx-json
```

Grant the package **Actions** Read access for the calling repository when using
`GITHUB_TOKEN`, or pass a PAT with `read:packages`.

## Quick start (local)

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  ghcr.io/pirlruc/ci-supply-chain:5.2.4 \
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
  ghcr.io/pirlruc/ci-supply-chain:5.2.4 \
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
docker pull ghcr.io/pirlruc/ci-supply-chain@sha256:f7abb77fd31aeb68bf31ff391ed0e54825f706314607dc1570088e19d3d6c55c

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/pirlruc/ci-supply-chain@sha256:f7abb77fd31aeb68bf31ff391ed0e54825f706314607dc1570088e19d3d6c55c
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries embed dependency CVEs that only clear when upstream publishes
a newer digest. The publish gate uses `--pkg-types library`.

## License

MIT
