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

OpenSSF Scorecard (`ossf/scorecard-action@v2.4.3`). Skips forks and Dependabot.
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

Public package pages:
[docker-hub-ci-lint.md](docker-hub-ci-lint.md) /
[github-packages-ci-lint.md](github-packages-ci-lint.md),
[docker-hub-ci-supply-chain.md](docker-hub-ci-supply-chain.md) /
[github-packages-ci-supply-chain.md](github-packages-ci-supply-chain.md).

Pass `image_title`, `image_description`, `image_documentation`, `image_url`,
`image_vendor`, `dockerhub_readme`, and `dockerhub_short_description` into
containerdevops `container-publish` so OCI labels describe the image (not the
repository) and Hub Overview stays in sync.

`docker/ci-base/` and the former `ci-base-image.yml` are deprecated (2.0.0).

---

## `devops-ci.yml` (self)

`push` / `pull_request` on `main` plus `workflow_dispatch`. Calls the `common-*`
reusables against this repository (`scripts_ref: ${{ github.sha }}`).
