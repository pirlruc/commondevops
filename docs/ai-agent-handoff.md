# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (PRIVATE) |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, release + `ci-lint` / `ci-supply-chain` images |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-lint-image.yml`, `ci-supply-chain-image.yml`, `scripts/`, `docker/ci-lint/`,
`docker/ci-supply-chain/`. Consumers pin `pirlruc/commondevops@<sha|tag>` and pass
matching `scripts_ref` + `checkout_token`.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops).

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| CMN-001 — reusable workflows | Done |
| CMN-002 — ci toolchain images | Done → split to ci-lint + ci-supply-chain (2.0.0) |
| CMN-003 — Dependabot SC-DEP | Done (private registry secrets still needed) |
| CMN-004 — ai-reviewer prompt | Done |
| CMN-005 — self-CI + security schedule | Done |
| CMN-006 — release-gated publish | Done |
| CMN-007 — CI-026 digest pins + grant | Done |
| CMN-008 — vendored thresholds fail-closed | Done |
| CMN-009 — grant license gate | Done |
| CMN-010 — DOCKER-PERF-001 size deviation | Done (700 MB per image; du -sxm /) |
| CMN-011 — Trivy ignores for donor binaries | Done |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag `1.1.0` → `6fe580c…` (deinit'd) |
| github-scaffold submodule | `f8a6ba1…` (deinit'd) |
| containerdevops (image callers) | `e673165f…` (re-pin after hygiene merge) |
| actions/checkout | `3d3c42e…` (v7.0.1) |

## Local image sizes (2026-08-11, `du -sxm /`)

| Image | Rootfs | Library gate (ignorefile) | Raw HIGH/CRITICAL |
|-------|--------|---------------------------|-------------------|
| ci-lint | ~545 MB | 0 | ~32 (OS + actionlint) |
| ci-supply-chain | ~575 MB | 0 | ~29 (OS + donors) |

## Commands

```bash
bash scripts/check-ci-local.sh
COMMONDEVOPS_CI_IMAGE=ci-lint:local COMMONDEVOPS_DOCKER_STEPS="actionlint shellcheck hadolint zizmor" \
  bash scripts/check-ci-docker.sh
bash scripts/pin-dhi-digests.sh docker/ci-lint/Dockerfile
THRESHOLDS_PATH=scripts/supply-chain.profile.thresholds.yml \
  python3 scripts/generate_grant_config.py
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/commondevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Caller permissions:** reusable workflows cannot escalate. Build callers must
  grant `packages: read` (container-build declares it) or the run dies at
  **startup_failure** before any job starts.
- **Private `checkout_token`:** Cross-repo callers need contents:read on this repo.
- **`scripts_ref`:** Must match the `uses:` pin.
- **License gate:** thresholds vendored at `scripts/supply-chain.profile.thresholds.yml`.
  Default engine is **grant**.
- **Submodules deinitialized**; hydrate before sync-templates.
- **Publish:** cut releases with a PAT (`GITHUB_TOKEN`-created releases do not trigger workflows).
- **Signing:** keep `sign: false` while private.
- **ci-base deprecated** — use `ci-lint` / `ci-supply-chain`; MAJOR 2.0.0.
- **DHI `status.d`:** after `apt-get purge` of `-dev` packages, also delete
  `/var/lib/dpkg/status.d/<pkg>` or Trivy reports phantom linux-libc-dev CVEs.
- **Size gate:** measure with `du -sxm /`, not `docker inspect .Size` (store-dependent).
- mcp must stay on 1.x (`==1.29.0`); mcp 2.x breaks semgrep.

## Suggested next work

1. Re-pin containerdevops after hygiene merge (ignorefile input + size gate).
2. Publish 2.0.0; grant Actions Read on new GHCR packages; create Hub repos.
3. Sync issues (`--update`) to close CMN-001…011 on GitHub.
4. Refresh donor digests / drop ignorefile entries before 2026-11-11.

## Recent history

- 2026-08-11: split ci-base → ci-lint + ci-supply-chain; packages:read fix;
  deviations at 700 MB; docker-hub docs; issues-sync-targets.yml.
- 2026-08-11: release `1.0.0` (ci-base); Scorecard advisory-on-private.

*Last updated: 2026-08-11*
