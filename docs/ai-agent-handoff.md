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

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag `1.1.0` → `6fe580c…` (deinit'd) |
| github-scaffold submodule | `f8a6ba1…` (deinit'd) |
| containerdevops (ci-base caller) | `4185836…` until PR1 merges; then merge SHA / `1.0.0` |
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

## Suggested next work

1. After containerdevops PR merges: bump CONTAINERDEVOPS_PIN; enable `tag_latest` + `runner_image: ""`.
2. Tag/release `1.0.0`; make `ghcr.io/pirlruc/ci-base` public.
3. Sync issues (`--update`) to close CMN-001…009 on GitHub.
4. Enable Dependabot private registries.

## Recent history

- 2026-08-11: grant license engine, fail-closed thresholds, CI-026 pins, release-gated
  ci-base publish, devops-ci/security triggers, submodule bump to guardrails 1.1.0.

*Last updated: 2026-08-11*
