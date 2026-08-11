# ci-lint (GitHub Packages)

Short-lived CI toolchain image for GitHub Actions jobs that run workflow lint
and secrets/SAST: actionlint, hadolint, shellcheck, zizmor, yamllint, gitleaks,
and semgrep. Not a product runtime — no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| GHCR | `ghcr.io/pirlruc/ci-lint` |
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
docker pull ghcr.io/pirlruc/ci-lint:2.0.1
```

If the package is private, authenticate with a PAT that has `read:packages`:

```bash
echo "$CR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/pirlruc/ci-lint:2.0.1
# or
docker pull ghcr.io/pirlruc/ci-lint@sha256:<digest>
```

## Use as a GitHub Actions job container

```yaml
jobs:
  lint:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/pirlruc/ci-lint:2.0.1
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - run: actionlint .github/workflows/*.yml
```

Grant the package **Actions** Read access for the calling repository when using
`GITHUB_TOKEN`, or pass a PAT with `read:packages`.

## Quick start (local)

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  ghcr.io/pirlruc/ci-lint:2.0.1 \
  actionlint .github/workflows/*.yml
```

Hardened local run:

```bash
docker run --rm \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --tmpfs /tmp:rw,noexec,nosuid,size=256m \
  -v "$PWD:/workspace:ro" -w /workspace \
  ghcr.io/pirlruc/ci-lint:2.0.1 \
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

## Verify a publish

```bash
docker pull ghcr.io/pirlruc/ci-lint@sha256:<digest>

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/pirlruc/ci-lint@sha256:<digest>
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries (notably actionlint) embed stdlib CVEs that only clear when
upstream publishes a newer digest. The publish gate uses `--pkg-types library`.

## License

MIT
