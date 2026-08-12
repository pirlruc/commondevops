# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (PRIVATE) |
| **Branch** | `feature-trivy-ignore-and-release-contract` (land on `main`) |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, release + `ci-lint` / `ci-supply-chain` images |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-lint-image.yml`, `ci-supply-chain-image.yml`, `scripts/`, `docker/ci-lint/`,
`docker/ci-supply-chain/`. Consumers pin `pirlruc/commondevops@<sha|tag>` and pass
matching `scripts_ref` + `checkout_token`.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops) tag `2.2.0`.

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| CMN-001…CMN-012 | Done |
| CMN-WF-001 — Trivy ignore + posture scan | **Done** (this branch) |
| CMN-WF-002 — release_token + registry rescan | **Done** (this branch) |
| CMN-SC-001 — install hardening + pin + prompt | **Done** (this branch) |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag `1.1.0` → `6fe580c…` |
| github-scaffold submodule | `f8a6ba1…` |
| containerdevops (image callers + security rescan) | tag `2.2.0` → `0fb7bab3411a…` |
| actions/checkout | `3d3c42e…` (v7.0.1) |
| Release | pending `2.1.0` (this branch) |

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
docker run --rm -v "$PWD:/src:ro" -w /src --entrypoint actionlint ci-lint:local .github/workflows/*.yml
docker run --rm -v "$PWD:/src:ro" -w /src --entrypoint shellcheck ci-lint:local scripts/*.sh
# Prove posture vs blocking ignorefile delta:
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:/work:ro" -w /work \
  aquasec/trivy:0.73.0 image --pkg-types library --severity HIGH,CRITICAL \
  --ignorefile docker/ci-lint/.trivyignore.yaml ci-lint:local
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.73.0 image --pkg-types library --severity HIGH,CRITICAL ci-lint:local
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/commondevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Caller permissions:** reusable workflows cannot escalate. Build callers must
  grant `packages: read` (container-build declares it) or the run dies at
  **startup_failure** before any job starts.
- **ignorefile:** blocking scans pass per-image files under `docker/ci-*/`. Posture
  scans must set `ignorefile: none` (containerdevops ≥ 2.2.0) or the caller-root
  fallback silently filters findings. Root `.trivyignore.yaml` was removed.
- **OCI labels:** pass `image_title` / `image_description` into containerdevops
  publish or the package page shows the repository description. Hub Overview needs
  `dockerhub_readme` + Hub token with read/write/delete (admin) scope.
- **Private `checkout_token`:** Cross-repo callers need contents:read on this repo.
- **`scripts_ref`:** Must match the `uses:` pin.
- **License gate:** thresholds vendored at `scripts/supply-chain.profile.thresholds.yml`.
  Default engine is **grant**.
- **Publish / release_token:** cut releases with a PAT (`GITHUB_TOKEN`-created
  releases do not trigger workflows). Pass `secrets.release_token` into
  `common-release.yml` when the release-event chain matters.
- **Signing:** keep `sign: false` while private.
- **ci-base deprecated** — stub only under `docker/ci-base/`; use `ci-lint` /
  `ci-supply-chain`.
- **DHI `status.d`:** after `apt-get purge` of `-dev` packages, also delete
  `/var/lib/dpkg/status.d/<pkg>` or Trivy reports phantom linux-libc-dev CVEs.
- **Size gate:** measure with `du -sxm /`, not `docker inspect .Size` (store-dependent).
- mcp must stay on 1.x (`==1.29.0`); mcp 2.x breaks semgrep.
- **Dependabot registries:** personal private repos need `registries:` wired to
  Dependabot secrets (`DEPENDABOT_GITHUB_TOKEN`, `DOCKERHUB_*`). Without them,
  updates fail with 401/403 on private submodules, reusable workflows, and `dhi.io`.
- **install-common-tools.sh:** versions + SHA256 digests are manual (not Dependabot).
- **Local vs Actions:** nested `workflow_call` composition is not exercised by `act`
  (not installed). Prefer `actionlint`/`zizmor`/disposable install tests before push.

## Suggested next work

1. After merge: tag/release `2.1.0` with a PAT; watch ci-lint / ci-supply-chain publish.
2. Grant Actions Read on GHCR packages; keep Hub repos public.
3. Refresh donor digests / drop ignorefile entries before 2026-11-11.

## Recent history

- 2026-08-12: CMN-WF-001 / CMN-WF-002 / CMN-SC-001 — per-image ignorefiles,
  posture `ignorefile: none`, `release_token`, real registry rescan, install
  SHA256 + actionlint tarball, pin containerdevops `2.2.0`, tighten
  continuous-improvement evidence rule.
- 2026-08-12: Dependabot `all-dependencies` (scorecard-action 2.4.4, codeql upload-sarif).
- 2026-08-12: wire Dependabot `registries:` for private git + dhi.io.
- 2026-08-12: CMN-012 — re-pin containerdevops, image metadata, Hub/GHCR docs;
  releases `2.0.2` (prefer over `2.0.1`).
- 2026-08-11: split ci-base → ci-lint + ci-supply-chain; release `2.0.0`.

*Last updated: 2026-08-12*
