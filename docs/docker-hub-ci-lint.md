# ci-lint

Short-lived CI toolchain image for GitHub Actions jobs that run workflow lint
and secrets/SAST: actionlint, hadolint, shellcheck, zizmor, yamllint, gitleaks,
and semgrep. Not a product runtime — no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| Docker Hub | `pirlruc/ci-lint` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |

### Tags

| Tag | Meaning |
|-----|---------|
| `5.1.1` / `5.1.1-alpine` | Immutable Alpine `sha256:35a82a43839e0969dc7c44d63c36b5c97cdefb20c6d3112255f52c09444042a1` |
| `5.1.1-debian` | Immutable Debian `sha256:6834b69583a9f67ac21bd06167672e793ce2cba1c14e646a98108e0fc9512dcd` |
| `5.1.0` / `5.1.0-alpine` | Previous Alpine `sha256:fc7d91c3ad2ca946e50395227b86396ac92d90afa14e9ca8c301909a5424085c` |
| `5.1.0-debian` | Previous Debian `sha256:c46d04b224d6a7e3227c02aa693c6cce277614be9432f6a6bcc88e8dbbbe1a7d` |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Alpine owns the unsuffixed tags because it currently has the lower OS vulnerability
posture on the DHI catalog (0 CRITICAL OS findings vs Debian). Prefer an explicit
`-alpine` / `-debian` suffix when the libc matters; prefer a digest in production.
`latest` equals `latest-alpine` (`flavor: latest=false`). A monthly rebuild may
move `latest` off the SemVer tag — pin the digest, not `latest`.

```bash
docker pull pirlruc/ci-lint:5.1.1
# or
docker pull pirlruc/ci-lint:5.1.1-debian
docker pull pirlruc/ci-lint@sha256:35a82a43839e0969dc7c44d63c36b5c97cdefb20c6d3112255f52c09444042a1
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-lint:5.1.1 \
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
  pirlruc/ci-lint:5.1.1 \
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
docker pull pirlruc/ci-lint@sha256:35a82a43839e0969dc7c44d63c36b5c97cdefb20c6d3112255f52c09444042a1

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  pirlruc/ci-lint@sha256:35a82a43839e0969dc7c44d63c36b5c97cdefb20c6d3112255f52c09444042a1
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries (notably actionlint) embed stdlib CVEs that only clear when
upstream publishes a newer digest. The publish gate uses `--pkg-types library`.
shellcheck and gitleaks on the Alpine variant are copied from the Debian DHI
donors (no Alpine DHI build exists; both binaries are statically linked).

## License

MIT
