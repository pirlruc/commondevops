# Reusable workflows

All workflows support `workflow_call` and `workflow_dispatch`. Top-level
`permissions: {}` (CI-025); jobs grant least privilege. Secret-using jobs skip
when `github.actor == 'dependabot[bot]'` (CI-024). Nested script checkout uses
`actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1) with
`persist-credentials: false`.

Shared inputs:

| Input | Type | Default | Notes |
|-------|------|---------|-------|
| `blocking` | bool | `false` | `false` → `continue-on-error` (advisory) |
| `working_directory` | string | `.` | Where applicable |
| `scripts_ref` | string | `""` | Must match caller `uses:` SHA; falls back to `github.sha` |
| `checkout_token` (secret) | string | — | PAT with `contents:read` on `pirlruc/commondevops` for private cross-repo callers |

---

## `common-infra-lint.yml`

Runs **actionlint**, **shellcheck**, **hadolint**, **zizmor** on `ubuntu-24.04`
via `scripts/install-common-tools.sh` (host path). Prefer running the same
commands inside `ghcr.io/pirlruc/ci-lint` for version lockstep.

| Input | Default | Notes |
|-------|---------|-------|
| `shell_scripts` | `""` | Space-separated / glob; empty → `scripts/*.sh` |
| `dockerfiles` | `""` | Empty → `docker/**/Dockerfile` |

---

## `common-doc-verify.yml`

Documentation-repo checks on `ubuntu-24.04`. Inline steps are POSIX `sh`.
Needs `contents: read`. Cross-repo callers pass `checkout_token` and matching
`scripts_ref` (same contract as `common-infra-lint.yml`).

YAML parse and link lint use **caller-vendored** scripts
(`scripts/validate-yaml.py`, `scripts/lint-doc-links.py`). Missing scripts are
skipped with a note — this workflow does not clone sibling repos.

Ruff is installed in a job-local venv at `ruff==0.14.10` (guardrails ci-python pin).
Empty path inputs skip that tool.

| Input | Default | Notes |
|-------|---------|-------|
| `shell_scripts` | `""` | Space-separated / glob; empty → skip shellcheck |
| `ruff_paths` | `""` | Space-separated / glob; empty → skip ruff |
| `yaml_files` | `""` | Space-separated paths passed to `validate-yaml.py` |
| `yaml_globs` | `""` | Space-separated patterns passed as `--glob` (Python expands them) |
| `run_link_lint` | `false` | Run `scripts/lint-doc-links.py` when that file exists |

Doc repos still need `COMMONDEVOPS_READ_TOKEN` to fetch this private reusable
and its `scripts/`. Ship the workflow first; wire callers after the token exists.

Pin the commit that introduced this file (after commondevops PR #62 merges);
do not reuse older consumer pins that predate it.

---

## `common-scaffold-verify.yml`

Thin github-scaffold checks. Does **not** require `GUARDRAILS_READ_TOKEN`.
Needs `contents: read`. Fetches tags so `git describe` works on PRs.

| Check | When it runs |
|-------|----------------|
| `python3 scripts/issues-sync.py --yaml docs/issues.yml --validate-only` | `scripts/issues-sync.py` and `docs/issues.yml` exist |
| `SCAFFOLD_REF` default equals `git describe --tags --abbrev=0` | `scripts/setup-library-submodules.sh` exists |

`scripts_ref` must still equal the caller `uses:` pin (CI-018). This reusable
does not sparse-checkout commondevops scripts.

Pin the commit that introduced this file (after PR #62 merges).

---

## `common-secrets-sast.yml`

| Step | Tool |
|------|------|
| Secrets | gitleaks (`--config .gitleaks.toml` when present) |
| SAST | semgrep `1.172.0` (`--config auto`, plus `.semgrep.yml` when present) |

Needs `contents: read` + `security-events: write`. Full history checkout for
gitleaks ranges. Prefer `ghcr.io/pirlruc/ci-lint` for the same toolset.

---

## `common-supply-chain.yml`

| Step | Artifact / gate |
|------|-----------------|
| Syft | `scan-results/sbom-cdx.json` + `sbom-spdx.json` |
| Grype | Fail on high (advisory when `blocking: false`) |
| Trivy fs | HIGH/CRITICAL + SARIF upload |
| License | **grant** (default) or `scripts/license_gate.py` (`license_engine`) |

| Input | Default | Notes |
|-------|---------|-------|
| `license_deny_list` | `"[]"` | JSON array string |
| `license_engine` | `grant` | `grant` or `spdx-deny` |

Thresholds are **vendored** at `scripts/supply-chain.profile.thresholds.yml`
(not `docs/guardrails/…` — the submodule is often deinitialized for consumers).

Guardrail IDs: SC-SBOM-*, SC-LIC-*, language-local SEC for Trivy/Grype as applicable.
Prefer `ghcr.io/pirlruc/ci-supply-chain` for the scanner binaries.

---

## `common-scorecard.yml`

OpenSSF Scorecard (`ossf/scorecard-action@v2.4.4`). Skips forks and Dependabot.
Permissions: `security-events: write`, `id-token: write`.

| Input | Default |
|-------|---------|
| `publish_results` | `true` |

Private Free-plan repos: pass optional `SCORECARD_TOKEN` (classic PAT, `repo`
scope) or Scorecard stays advisory when `repository.private` is true.

---

## `common-release.yml`

| Input | Default | Notes |
|-------|---------|-------|
| `tag` | (required) | Must match `vMAJOR.MINOR.PATCH…` and exist |
| `attach_sbom` | `false` | Downloads `sbom_artifact` when true |
| `sign` | `false` | Emits cosign guidance; keyless needs public/GHEC |

| Secret | Required | Notes |
|--------|----------|-------|
| `release_token` | Recommended | PAT with `contents:write`. Prefer over `github.token` so the published release fires `on: release` workflows (GITHUB_TOKEN-created releases do not). |

Permissions: `contents: write`; `id-token: write` when signing is requested
(job always requests `id-token` write so the expression stays static — unused when
`sign: false`).

---

## `ci-lint-image.yml` / `ci-supply-chain-image.yml` (callers)

Thin callers into containerdevops for lint/build/scan/publish of
`docker/ci-lint` and `docker/ci-supply-chain`. Secrets:
`CONTAINERDEVOPS_READ_TOKEN`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.
`dhi_login: true`. `image_max_size_mb: "700"` (rootfs via `du -sxm /`).
Optional Hub push via `dockerhub_image`. Caller must grant `packages: read` on
the build job (container-build declares it).

Trivy ignorefile contract (containerdevops ≥ `2.2.0`):

| Job | `ignorefile` |
|-----|--------------|
| Blocking `scan` | `docker/ci-lint/.trivyignore.yaml` or `docker/ci-supply-chain/.trivyignore.yaml` |
| Advisory `scan-posture` | `none` (disables caller-root fallback so findings are unfiltered) |

Public package pages:
[docker-hub-ci-lint.md](docker-hub-ci-lint.md) /
[github-packages-ci-lint.md](github-packages-ci-lint.md),
[docker-hub-ci-supply-chain.md](docker-hub-ci-supply-chain.md) /
[github-packages-ci-supply-chain.md](github-packages-ci-supply-chain.md).

Pass `image_title`, `image_description`, `image_documentation`, `image_url`,
`image_vendor`, `dockerhub_readme`, and `dockerhub_short_description` into
containerdevops `container-publish` so OCI labels describe the image (not the
repository) and Hub Overview stays in sync.

`ci-supply-chain` builds Debian (`Dockerfile`) and Alpine 3.24
(`Dockerfile.alpine`) variants. Publish uses `tag_suffix: -debian` /
`-alpine`; Alpine sets `tag_alias_unsuffixed: true` so it owns `<version>` and
`latest`. Distinct `artifact_name` / `results_artifact` / `sarif_category`
values keep parallel jobs from colliding (containerdevops ≥ `2.3.0`).

---

## `devops-ci.yml` (self)

`push` / `pull_request` on `main` plus `workflow_dispatch`. Calls the `common-*`
reusables against this repository (`scripts_ref: ${{ github.sha }}`).

## `devops-security.yml` (scheduled)

Weekly secrets/SAST, supply-chain, Scorecard, and registry rescans of
`ghcr.io/pirlruc/ci-lint:latest` and `ghcr.io/pirlruc/ci-supply-chain:latest`
via containerdevops `container-published-rescan.yml@3.0.2` (`3607bf0…`; probe
skips the scan when the package is not yet pullable). Image CI (`ci-lint-image.yml`,
`ci-supply-chain-image.yml`) still calls `container-scan.yml` at the same SHA.
