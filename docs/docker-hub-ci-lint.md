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
| `5.2.4` / `5.2.4-alpine` | Immutable Alpine `sha256:e0a51c64b004c6f4e4ca1672f3bb865aaf03d91bd8a2e228e0fa39be1174dfb4` |
| `5.2.4-debian` | Immutable Debian `sha256:618b469a95b60097eb709830cbe3ee079a78f614ad0bf74b5643d4c8c0895cec` |
| `5.2.2` / `5.2.2-alpine` | Previous Alpine `sha256:fd24e836c677e044163aab19e1e7d49d92ce34576deb7970b1ae16ea52b36d1b` |
| `5.2.2-debian` | Previous Debian `sha256:2cb20ba2d39f55ccc4195acc162013162682cb3bcccc31c300261965ca9b30c1` |
| `5.1.0` / `5.1.0-alpine` | Previous Alpine `sha256:fc7d91c3ad2ca946e50395227b86396ac92d90afa14e9ca8c301909a5424085c` |
| `5.1.0-debian` | Previous Debian `sha256:c46d04b224d6a7e3227c02aa693c6cce277614be9432f6a6bcc88e8dbbbe1a7d` |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Tags through 5.2.4: Alpine owns the unsuffixed tags. The next publish flips
that. semgrep 1.179.0 has no musllinux wheel, so Debian owns unsuffixed tags
and `latest`, and the Alpine variant does not include semgrep. Prefer an
explicit `-alpine` / `-debian` suffix when the libc matters; prefer a digest
in production. A monthly rebuild may move `latest` off the SemVer tag — pin
the digest, not `latest`.

```bash
docker pull pirlruc/ci-lint:5.2.4
# or
docker pull pirlruc/ci-lint:5.2.4-debian
docker pull pirlruc/ci-lint@sha256:e0a51c64b004c6f4e4ca1672f3bb865aaf03d91bd8a2e228e0fa39be1174dfb4
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-lint:5.2.4 \
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
  pirlruc/ci-lint:5.2.4 \
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
docker pull pirlruc/ci-lint@sha256:e0a51c64b004c6f4e4ca1672f3bb865aaf03d91bd8a2e228e0fa39be1174dfb4

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/commondevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  pirlruc/ci-lint@sha256:e0a51c64b004c6f4e4ca1672f3bb865aaf03d91bd8a2e228e0fa39be1174dfb4
```

Signing runs only when the source repository is public.

## Vulnerabilities

Donor Go binaries (notably actionlint) embed stdlib CVEs that only clear when
upstream publishes a newer digest. The publish gate uses `--pkg-types library`.
shellcheck and gitleaks on the Alpine variant are copied from the Debian DHI
donors (no Alpine DHI build exists; both binaries are statically linked).

## License

MIT
