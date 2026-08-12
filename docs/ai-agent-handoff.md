# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (PRIVATE) |
| **Branch** | `feature-drop-ci-base-and-alpine-supply-chain` (land on `main`) |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, release + `ci-lint` / `ci-supply-chain` images |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-lint-image.yml`, `ci-supply-chain-image.yml`, `scripts/`, `docker/ci-lint/`,
`docker/ci-supply-chain/`. Consumers pin `pirlruc/commondevops@<sha|tag>` and pass
matching `scripts_ref` + `checkout_token`.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops) tag `2.3.0`.

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| CMN-001…CMN-012 | Done |
| CMN-WF-001 — Trivy ignore + posture scan | Done |
| CMN-WF-002 — release_token + registry rescan | Done |
| CMN-SC-001 — install hardening + pin + prompt | Done |
| CMN-IMG-001 — Alpine ci-supply-chain variant | **In progress** (this branch) |
| CMN-IMG-002 — Remove docker/ci-base | **In progress** (this branch) |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | commit `5a7ac83…` (post ci-base ref drop) |
| github-scaffold submodule | `f8a6ba1…` |
| containerdevops (image callers + security rescan) | tag `2.3.0` → `010bf9bf9033…` |
| actions/checkout | `3d3c42e…` (v7.0.1) |
| Release | pending `3.0.0` (major — unsuffixed `ci-supply-chain` moves to musl/Alpine) |

## Local image sizes (2026-08-12, `du -sxm /`)

| Image | Rootfs | Library gate (ignorefile) | Notes |
|-------|--------|---------------------------|-------|
| ci-lint | ~545 MB | 0 | debian13 |
| ci-supply-chain (debian) | ~575 MB | 0 | size gate 700 |
| ci-supply-chain (alpine) | ~722 MB | 0 with ignorefile | size gate 800; grant/grype donor HIGHs |

## Commands

```bash
bash scripts/check-ci-local.sh
COMMONDEVOPS_CI_IMAGE=ci-lint:local COMMONDEVOPS_DOCKER_STEPS="actionlint shellcheck hadolint zizmor" \
  bash scripts/check-ci-docker.sh
docker build -t ci-supply-chain:alpine-local -f docker/ci-supply-chain/Dockerfile.alpine docker/ci-supply-chain
docker run --rm --user root --entrypoint sh ci-supply-chain:alpine-local -c 'du -sxm /'
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/docker/ci-supply-chain/.trivyignore.yaml:/tmp/.trivyignore.yaml:ro" \
  aquasec/trivy:0.73.0 image --pkg-types library --severity HIGH,CRITICAL \
  --ignorefile /tmp/.trivyignore.yaml ci-supply-chain:alpine-local
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
- **Variant jobs:** parallel debian/alpine builds need unique `artifact_name`,
  `results_artifact`, and `sarif_category` (containerdevops ≥ 2.3.0).
- **Alpine owns unsuffixed tags** for `ci-supply-chain` — consumers on glibc must
  pin `:*-debian` after `3.0.0`.
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

1. After merge: tag/release `3.0.0` with a PAT; watch dual-variant ci-supply-chain publish.
2. Re-pin containerdevops `CI_BASE` after any later ci-lint release if needed.
3. Guardrails PR to drop stale `ci-base` reference in `ci/guardrails.md`, then submodule bump.
4. Refresh donor digests / drop ignorefile entries before 2026-11-11.

## Recent history

- 2026-08-12: CMN-IMG-001 / CMN-IMG-002 — delete `docker/ci-base`, add Alpine
  `ci-supply-chain` variant with `-alpine`/`-debian` tags (Alpine owns unsuffixed),
  re-pin containerdevops `2.3.0`.
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
