# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (PRIVATE) |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, release + `ci-base` image |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-base-image.yml`, `scripts/`, `docker/ci-base/`. Consumers pin
`pirlruc/commondevops@<sha|tag>` and pass matching `scripts_ref` +
`checkout_token`.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops).

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| CMN-001 — reusable workflows | Done |
| CMN-002 — ci-base image | Done (awaiting first release publish) |
| CMN-003 — Dependabot SC-DEP | Done (private registry secrets still needed) |
| CMN-004 — ai-reviewer prompt | Done |
| CMN-005 — self-CI + security schedule | Done |
| CMN-006 — release-gated publish | Done |
| CMN-007 — CI-026 digest pins + grant | Done |
| CMN-008 — vendored thresholds fail-closed | Done |
| CMN-009 — grant license gate | Done |
| CMN-010 — DOCKER-PERF-001 size deviation | In progress (on PR) |
| CMN-011 — Trivy ignores for donor binaries | In progress (on PR) |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag `1.1.0` → `6fe580c…` (deinit'd) |
| github-scaffold submodule | `f8a6ba1…` (deinit'd) |
| containerdevops (ci-base caller) | `304cd8f1…` (PR #32 ignorefile + rescan probe) |
| actions/checkout | `3d3c42e…` (v7.0.1) |

## Commands

```bash
bash scripts/check-ci-local.sh
bash scripts/pin-dhi-digests.sh docker/ci-base/Dockerfile
THRESHOLDS_PATH=scripts/supply-chain.profile.thresholds.yml \
  python3 scripts/generate_grant_config.py
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/commondevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Private `checkout_token`:** Cross-repo callers need contents:read on this repo.
- **`scripts_ref`:** Must match the `uses:` pin.
- **License gate:** thresholds are vendored at `scripts/supply-chain.profile.thresholds.yml`
  (not `docs/guardrails/`). Default engine is **grant** with `--disable-file-search`.
- **Submodules deinitialized** (bor-cpp style); hydrate before sync-templates.
- **Publish:** `release: [published]` + monthly schedule; cut releases with `gh release create`
  under a PAT (GITHUB_TOKEN-created releases do not trigger workflows).
- **Signing:** keep `sign: false` while private; record deviation if required.
- Dependabot needs Dependabot secrets for private `containerdevops` + `dhi.io`.
- **ci-base Trivy:** donor-static HIGH CVEs are path-scoped in `.trivyignore.yaml`
  (review 2026-11-11, CMN-011). Do not ignore PyJWT/mcp — bump via Dockerfile.
  mcp must stay on 1.x (`==1.29.0`); mcp 2.x drops FastMCP and breaks semgrep.
- **container-scan ignorefile** requires containerdevops ≥ `304cd8f1…`.

## Suggested next work

1. Merge this PR; cut annotated tag + GitHub Release `1.0.0` (PAT) to publish ci-base.
2. Make `ghcr.io/pirlruc/ci-base` package public; verify unauthenticated pull.
3. Cut containerdevops `1.0.0`; make `ci-container` public; re-pin this repo to that tag.
4. Sync issues (`--update`) to close CMN-001…011 on GitHub; enable Dependabot private registries.
5. Refresh donor digests / drop `.trivyignore.yaml` entries when upstream ships fixes (before 2026-11-11).

## Recent history

- 2026-08-11: actionlint 1.7.12, semgrep 1.172.0 + mcp==1.29.0 override, `.trivyignore.yaml`
  (CMN-011); pin containerdevops `304cd8f1…` (PR #32 ignorefile support).
- 2026-08-11: CONTAINERDEVOPS_PIN → `c3851646…` (PR #29); pass `scripts_token` +
  `checkout_token: github.token` for cross-repo reusable calls.
- 2026-08-11: restored self-CI triggers; earlier pin `5117142…` (PR #21 merge);
  enabled `runner_image: ""`, `tag_latest`, `verify_command`.
- 2026-08-11: grant license engine, fail-closed thresholds, CI-026 pins, release-gated
  ci-base publish, devops-ci/security triggers, submodule bump to guardrails 1.1.0.

*Last updated: 2026-08-11*
