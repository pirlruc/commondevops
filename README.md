# commondevops

Reusable GitHub Actions, scripts, and the shared `ci-base` image for org-wide
infra lint, secrets/SAST, supply-chain, Scorecard, and release gates.

| | |
|---|---|
| **Remote** | https://github.com/pirlruc/commondevops |
| **Role** | Cross-language CI infrastructure (pairs with [containerdevops](https://github.com/pirlruc/containerdevops) and [pydevops](https://github.com/pirlruc/pydevops)) |
| **Guardrails** | Pinned at `docs/guardrails/` ([pirlruc/guardrails](https://github.com/pirlruc/guardrails) tag `1.0.0`) |

## Reusable workflows

Pin every `uses:` to a **commit SHA** (not `@main`). Pass the same SHA as
`scripts_ref`, and pass `checkout_token` when the caller is a different
**private** repository.

| Workflow | Purpose |
|----------|---------|
| [`common-infra-lint.yml`](.github/workflows/common-infra-lint.yml) | actionlint, shellcheck, hadolint, zizmor |
| [`common-secrets-sast.yml`](.github/workflows/common-secrets-sast.yml) | gitleaks + semgrep |
| [`common-supply-chain.yml`](.github/workflows/common-supply-chain.yml) | Syft SBOM, Grype, Trivy fs, license gate |
| [`common-scorecard.yml`](.github/workflows/common-scorecard.yml) | OpenSSF Scorecard |
| [`common-release.yml`](.github/workflows/common-release.yml) | Tag validation + GitHub Release |

See [docs/workflows.md](docs/workflows.md) for inputs, secrets, and examples.

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
bash scripts/check-ci-local.sh
# Missing host tools → scripts/check-ci-docker.sh (ghcr.io/pirlruc/ci-base:latest)
```

## ci-base image

[`docker/ci-base/`](docker/ci-base/) assembles DHI-pinned syft/grype/trivy/shellcheck
plus hadolint, actionlint, and uv-installed zizmor/yamllint/semgrep. Built and
published by [`.github/workflows/ci-base-image.yml`](.github/workflows/ci-base-image.yml)
via [containerdevops](https://github.com/pirlruc/containerdevops)@`09dded47`.

## Submodules

| Path | Remote | Pin |
|------|--------|-----|
| `docs/guardrails` | https://github.com/pirlruc/guardrails.git | tag `1.0.0` → commit `925b9f3…` |
| `.github/scaffold` | https://github.com/pirlruc/github-scaffold.git | `0db5890…` |

```bash
git submodule update --init --recursive
bash .github/scaffold/scripts/sync-templates.sh
```
