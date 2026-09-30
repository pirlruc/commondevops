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
| `5.2.2` / `5.2.2-alpine` | Immutable Alpine `sha256:fd24e836c677e044163aab19e1e7d49d92ce34576deb7970b1ae16ea52b36d1b` |
| `5.2.2-debian` | Immutable Debian `sha256:2cb20ba2d39f55ccc4195acc162013162682cb3bcccc31c300261965ca9b30c1` |
| `5.1.0` / `5.1.0-alpine` | Previous Alpine `sha256:fc7d91c3ad2ca946e50395227b86396ac92d90afa14e9ca8c301909a5424085c` |
| `5.1.0-debian` | Previous Debian `sha256:c46d04b224d6a7e3227c02aa693c6cce277614be9432f6a6bcc88e8dbbbe1a7d` |
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
docker pull ghcr.io/pirlruc/ci-lint:5.2.2
```

If the package is private, authenticate with a PAT that has `read:packages`:

```bash
echo "$CR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/pirlruc/ci-lint:5.2.2
# or
docker pull ghcr.io/pirlruc/ci-lint@sha256:fd24e836c677e044163aab19e1e7d49d92ce34576deb7970b1ae16ea52b36d1b
```

## Use as a GitHub Actions job container

```yaml
jobs:
  lint:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/pirlruc/ci-lint:5.2.2
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - run: actionlint .github/workflows/*.yml
```

Grant the package **Actions** Read access for the calling repository when using
`GITHUB_TOKEN`, or pass a PAT with `read:packages`.

## Quick start (local)

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  ghcr.io/pirlruc/ci-lint:5.2.2 \
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
  ghcr.io/pirlruc/ci-lint:5.2.2 \
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
docker pull ghcr.io/pirlruc/ci-lint@sha256:fd24e836c677e044163aab19e1e7d49d92ce34576deb7970b1ae16ea52b36d1b

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/pirlruc/ci-lint@sha256:fd24e836c677e044163aab19e1e7d49d92ce34576deb7970b1ae16ea52b36d1b
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries (notably actionlint) embed stdlib CVEs that only clear when
upstream publishes a newer digest. The publish gate uses `--pkg-types library`.
shellcheck and gitleaks on the Alpine variant are copied from the Debian DHI
donors (no Alpine DHI build exists; both binaries are statically linked).

## License

MIT
