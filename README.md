# commondevops

Reusable GitHub Actions, scripts, and shared CI toolchain images (`ci-lint`,
`ci-supply-chain`) for org-wide infra lint, secrets/SAST, supply-chain,
Scorecard, and release gates.

| | |
|---|---|
| **Remote** | https://github.com/pirlruc/commondevops |
| **Role** | Cross-language CI infrastructure (pairs with [containerdevops](https://github.com/pirlruc/containerdevops) and [pydevops](https://github.com/pirlruc/pydevops)) |
| **Guardrails** | Pinned at `docs/guardrails/` ([pirlruc/guardrails](https://github.com/pirlruc/guardrails) tag `1.6.0`) |

## Reusable workflows

Pin every `uses:` to a **commit SHA** (not `@main`). Pass the same SHA as
`scripts_ref`, and pass `checkout_token` when the caller is a different
**private** repository.

| Workflow | Purpose |
|----------|---------|
| [`common-infra-lint.yml`](.github/workflows/common-infra-lint.yml) | actionlint, shellcheck, hadolint, zizmor |
| [`common-doc-verify.yml`](.github/workflows/common-doc-verify.yml) | shellcheck, ruff, caller YAML parse, markdown link lint |
| [`common-scaffold-verify.yml`](.github/workflows/common-scaffold-verify.yml) | issues-sync `--validate-only` + `SCAFFOLD_REF` vs newest tag |
| [`common-secrets-sast.yml`](.github/workflows/common-secrets-sast.yml) | gitleaks + semgrep |
| [`common-supply-chain.yml`](.github/workflows/common-supply-chain.yml) | Syft SBOM, Grype, Trivy fs, license gate |
| [`common-scorecard.yml`](.github/workflows/common-scorecard.yml) | OpenSSF Scorecard |
| [`common-release.yml`](.github/workflows/common-release.yml) | Tag validation + GitHub Release |

See [docs/workflows.md](docs/workflows.md) for inputs, secrets, the caller-permission
matrix, and examples.

GHCR package visibility and Actions access are manual (API PATCH returns 404).
Dispatch [`.github/workflows/ghcr-package-visibility.yml`](.github/workflows/ghcr-package-visibility.yml)
to print the UI steps for a package.

### Caller example

```yaml
jobs:
  infra:
    if: github.actor != 'dependabot[bot]'
    uses: pirlruc/commondevops/.github/workflows/common-infra-lint.yml@<sha>
    with:
      blocking: true
      scripts_ref: <sha>
    secrets:
      checkout_token: ${{ secrets.COMMONDEVOPS_READ_TOKEN }}
```

## Local parity

```bash
sh scripts/check-ci-local.sh
# Missing host tools → scripts/check-ci-docker.sh (POSIX sh; Alpine ci-lint has no bash)
# Prefer: COMMONDEVOPS_CI_IMAGE=ci-lint:alpine-local sh scripts/check-ci-local.sh
```

## Toolchain images

| Image | Contents | Docs |
|-------|----------|------|
| `ghcr.io/pirlruc/ci-lint` | actionlint, hadolint, shellcheck, zizmor, yamllint, gitleaks, semgrep — Alpine (default) and Debian (`-debian`) variants | [Hub](docs/docker-hub-ci-lint.md) · [GHCR](docs/github-packages-ci-lint.md) |
| `ghcr.io/pirlruc/ci-supply-chain` | syft, grype, trivy, grant — Alpine (default) and Debian (`-debian`) variants | [Hub](docs/docker-hub-ci-supply-chain.md) · [GHCR](docs/github-packages-ci-supply-chain.md) |

Built via [`ci-lint-image.yml`](.github/workflows/ci-lint-image.yml) and
[`ci-supply-chain-image.yml`](.github/workflows/ci-supply-chain-image.yml)
using [containerdevops](https://github.com/pirlruc/containerdevops).
Both images publish Debian (`-debian`) and Alpine (`-alpine`) variants;
Alpine owns the unsuffixed tags.

## Submodules

| Path | Remote | Pin |
|------|--------|-----|
| `docs/guardrails` | https://github.com/pirlruc/guardrails.git | tag `1.6.0` → commit `77cf16eb…` |
| `.github/scaffold` | https://github.com/pirlruc/github-scaffold.git | tag `1.5.0` → commit `9e04ed53…` |

```bash
git submodule update --init --recursive
bash .github/scaffold/scripts/sync-templates.sh
```
