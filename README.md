# commondevops

Reusable GitHub Actions, scripts, and shared CI toolchain images (`ci-lint`,
`ci-supply-chain`, `ci-iac`) for org-wide infra lint, secrets/SAST,
supply-chain, Scorecard, OpenTofu, SOPS, and release gates.

| | |
|---|---|
| **Remote** | https://github.com/pirlruc/commondevops |
| **Role** | Cross-language CI infrastructure (pairs with [containerdevops](https://github.com/pirlruc/containerdevops) and [pydevops](https://github.com/pirlruc/pydevops)) |
| **Guardrails** | Pinned at `docs/guardrails/` ([pirlruc/guardrails](https://github.com/pirlruc/guardrails) tag `1.13.1`) |
| **Changelog** | [CHANGELOG.md](CHANGELOG.md) |

## Reusable workflows

Pin every `uses:` to a **commit SHA** (not `@main`). Pass the same SHA as
`scripts_ref`, and pass `checkout_token` when the caller is a different
**private** repository. Callers of `common-infra-lint`, `common-secrets-sast`,
and `common-supply-chain` also grant `packages: read`. Those jobs pull a
private `ghcr.io/pirlruc` image with `container.credentials`.

| Workflow | Purpose |
|----------|---------|
| [`common-infra-lint.yml`](.github/workflows/common-infra-lint.yml) | actionlint, shellcheck, hadolint, zizmor |
| [`common-doc-verify.yml`](.github/workflows/common-doc-verify.yml) | shellcheck, ruff, caller YAML parse, markdown link lint |
| [`common-scaffold-verify.yml`](.github/workflows/common-scaffold-verify.yml) | issues-sync `--validate-only` + `SCAFFOLD_REF` vs newest tag |
| [`common-secrets-sast.yml`](.github/workflows/common-secrets-sast.yml) | gitleaks + semgrep |
| [`common-supply-chain.yml`](.github/workflows/common-supply-chain.yml) | Syft SBOM, Grype, Trivy fs, license gate |
| [`common-scorecard.yml`](.github/workflows/common-scorecard.yml) | OpenSSF Scorecard |
| [`common-release.yml`](.github/workflows/common-release.yml) | Tag validation + GitHub Release |
| [`artifact-sweep.yml`](.github/workflows/artifact-sweep.yml) | Scheduled delete of leftover `container-image*` artifacts |
| [`common-ansible-verify.yml`](.github/workflows/common-ansible-verify.yml) | yamllint, ansible-lint, the caller guardrail script, and Molecule |
| [`common-token-audit.yml`](.github/workflows/common-token-audit.yml) | Expiry check for the PATs the caller passes |
| [`common-tofu-verify.yml`](.github/workflows/common-tofu-verify.yml) | `tofu fmt`, `tofu validate`, and tflint from `ci-iac` |
| [`common-sops-verify.yml`](.github/workflows/common-sops-verify.yml) | SOPS ciphertext check from `ci-iac`. No Age private key |
| [`common-pins-verify.yml`](.github/workflows/common-pins-verify.yml) | Caller submodule gitlink assert |
| [`common-threshold-drift.yml`](.github/workflows/common-threshold-drift.yml) | Vendored threshold keys against the guardrails pin |

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
| `ghcr.io/pirlruc/ci-lint` | actionlint, hadolint, shellcheck, zizmor, yamllint, gitleaks, semgrep. Debian owns the unsuffixed tag. Alpine is `-alpine` and does not include semgrep | [Hub](docs/docker-hub-ci-lint.md) · [GHCR](docs/github-packages-ci-lint.md) |
| `ghcr.io/pirlruc/ci-supply-chain` | syft, grype, trivy, grant. Alpine owns the unsuffixed tag. Debian is `-debian` | [Hub](docs/docker-hub-ci-supply-chain.md) · [GHCR](docs/github-packages-ci-supply-chain.md) |
| `ghcr.io/pirlruc/ci-iac` | OpenTofu, tflint, sops, age, ansible-lint. Debian only. Published with release 5.4.0 | [Hub](docs/docker-hub-ci-iac.md) · [GHCR](docs/github-packages-ci-iac.md) |

Built via [`ci-lint-image.yml`](.github/workflows/ci-lint-image.yml),
[`ci-supply-chain-image.yml`](.github/workflows/ci-supply-chain-image.yml), and
[`ci-iac-image.yml`](.github/workflows/ci-iac-image.yml)
using [containerdevops](https://github.com/pirlruc/containerdevops).
Both `ci-lint` and `ci-supply-chain` publish Debian and Alpine variants.
From 5.3.0, Debian owns the unsuffixed `ci-lint` tags. Alpine owns the
unsuffixed `ci-supply-chain` tags. `ci-iac` is Debian only.

## Submodules

| Path | Remote | Pin |
|------|--------|-----|
| `docs/guardrails` | https://github.com/pirlruc/guardrails.git | tag `1.13.1` |
| `.github/scaffold` | https://github.com/pirlruc/github-scaffold.git | tag `1.10.0` |

```bash
git submodule update --init --recursive
bash .github/scaffold/scripts/sync-templates.sh
```
