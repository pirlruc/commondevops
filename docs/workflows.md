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
via `scripts/install-common-tools.sh` (v1; prefer `ghcr.io/pirlruc/ci-base` later).

| Input | Default | Notes |
|-------|---------|-------|
| `shell_scripts` | `""` | Space-separated / glob; empty → `scripts/*.sh` |
| `dockerfiles` | `""` | Empty → `docker/**/Dockerfile` |

---

## `common-secrets-sast.yml`

| Step | Tool |
|------|------|
| Secrets | gitleaks (`--config .gitleaks.toml` when present) |
| SAST | semgrep (`--config auto`, plus `.semgrep.yml` when present) |

Needs `contents: read` + `security-events: write`. Full history checkout for
gitleaks ranges.

---

## `common-supply-chain.yml`

| Step | Artifact / gate |
|------|-----------------|
| Syft | `scan-results/sbom-cdx.json` + `sbom-spdx.json` |
| Grype | Fail on high (advisory when `blocking: false`) |
| Trivy fs | HIGH/CRITICAL + SARIF upload |
| License | `scripts/license_gate.py` with `SPDX_SBOM_PATH` + `LICENSE_DENY_LIST` |

| Input | Default | Notes |
|-------|---------|-------|
| `license_deny_list` | `"[]"` | JSON array string; empty/`[]` → `docs/guardrails/supply-chain/profile.thresholds.yml` |

Guardrail IDs: SC-SBOM-*, SC-LIC-*, language-local SEC for Trivy/Grype as applicable.

---

## `common-scorecard.yml`

OpenSSF Scorecard (`ossf/scorecard-action@v2.4.3`). Skips forks and Dependabot.
Permissions: `security-events: write`, `id-token: write`.

| Input | Default |
|-------|---------|
| `publish_results` | `true` |

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

## `ci-base-image.yml` (caller)

Thin caller into containerdevops@`5117142` for lint/build/scan/publish of
`docker/ci-base`. Secrets: `CONTAINERDEVOPS_READ_TOKEN`, `DOCKERHUB_USERNAME`,
`DOCKERHUB_TOKEN`. `dhi_login: true`.

---

## `devops-ci.yml` (self)

`workflow_dispatch` that calls the `common-*` reusables against this repository
for smoke verification.
