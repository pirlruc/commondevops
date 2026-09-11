# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (PRIVATE) |
| **Branch** | `main` |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, release + `ci-lint` / `ci-supply-chain` images |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-lint-image.yml`, `ci-supply-chain-image.yml`, `scripts/`, `docker/ci-lint/`,
`docker/ci-supply-chain/`. Consumers pin `pirlruc/commondevops@<sha|tag>` and pass
matching `scripts_ref` + `checkout_token`.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops) tag `3.0.1`
→ `9a46e8437d369…` (reusable workflows, GHCR-login scan patch). Image tag `3.0.0` is Alpine `ci-container`
only — **do not** re-pin callers to `3.0.0` unless a reusable workflow changes.

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| CMN-001…CMN-012 | Done |
| CMN-WF-001 — Trivy ignore + posture scan | Done |
| CMN-WF-002 — release_token + registry rescan | Done |
| CMN-SC-001 — install hardening + pin + prompt | Done |
| CMN-IMG-001 — Alpine ci-supply-chain variant | Done (`3.0.0`) |
| CMN-IMG-002 — Remove docker/ci-base | Done (`3.0.0`) |
| CMN-IMG-003 — Alpine ci-lint variant | Done (`4.0.0`) |
| CMN-WF-003 — Alpine check-ci-docker.sh POSIX sh | Open (filed) |
| CMN-DOC-001 — Caller-contract docs | Open (filed) |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | commit `5a7ac83…` (post ci-base ref drop) |
| github-scaffold submodule | `f8a6ba1…` |
| containerdevops (image callers + security rescan) | tag `3.0.1` → `9a46e8437d369…` |
| actions/checkout | `3d3c42e…` (v7.0.1) |
| `ghcr.io/pirlruc/ci-lint` (alpine, unsuffixed) | `4.0.0` → `sha256:0a4691ba…` |
| `ghcr.io/pirlruc/ci-lint` (debian) | `4.0.0-debian` → `sha256:ed619755…` |
| Release | `4.0.0` (Alpine owns unsuffixed `ci-lint`) |

## Local image sizes / posture (2026-08-12, `du -sxm /`)

| Image | Rootfs | Posture (os+library, no ignore) | Notes |
|-------|--------|----------------------------------|-------|
| ci-lint debian | ~545 MB | 28 HIGH / 4 CRITICAL (20 OS) | size gate 700 |
| ci-lint alpine | ~752 MB | 12 HIGH / 0 CRITICAL (0 OS) | size gate 850; **owns unsuffixed** |
| ci-supply-chain debian | ~575 MB | — | size gate 700 |
| ci-supply-chain alpine | ~722 MB | — | size gate 800; owns unsuffixed |

## Commands

```bash
bash scripts/check-ci-local.sh
COMMONDEVOPS_CI_IMAGE=ci-lint:alpine-local COMMONDEVOPS_DOCKER_STEPS="actionlint shellcheck hadolint zizmor yamllint" \
  bash scripts/check-ci-docker.sh
docker build -t ci-lint:alpine-local -f docker/ci-lint/Dockerfile.alpine docker/ci-lint
docker run --rm ci-lint:alpine-local echo ok
docker run --rm --user root --entrypoint sh ci-lint:alpine-local -c 'du -sxm /'
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/docker/ci-lint/.trivyignore.yaml:/tmp/.trivyignore.yaml:ro" \
  aquasec/trivy:0.73.0 image --pkg-types library --severity HIGH,CRITICAL \
  --ignorefile /tmp/.trivyignore.yaml ci-lint:alpine-local
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/commondevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Caller permissions:** reusable workflows cannot escalate. Build callers must
  grant `packages: read` (container-build declares it) or the run dies at
  **startup_failure** before any job starts. Scan callers of a `ghcr.io/` image
  must also grant `packages: read` once containerdevops includes GHCR login in
  `container-scan.yml`.
- **ignorefile:** blocking scans pass per-image files under `docker/ci-*/`. Posture
  scans must set `ignorefile: none` (containerdevops ≥ 2.2.0) or the caller-root
  fallback silently filters findings. Root `.trivyignore.yaml` was removed.
- **Variant jobs:** parallel debian/alpine builds need unique `artifact_name`,
  `results_artifact`, and `sarif_category` (containerdevops ≥ 2.3.0).
- **Alpine owns unsuffixed tags** for `ci-supply-chain` and (as of `4.0.0`)
  `ci-lint` — consumers on glibc must pin `:*-debian`.
- **CMD is `sh`:** Alpine DHI has no bash. All toolchain images use `CMD ["sh"]`
  and `/bin/sh` in passwd. Do not restore `bash`.
- **shellcheck/gitleaks on Alpine:** no DHI alpine tag; copy static Debian donors.
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
- **GHCR inspect locally:** packages:read often missing on user tokens → 403; use
  Actions publish logs for digest/tag verification.
- **check-ci-local.sh:** `--no-docker` fails when tools are missing (no silent pass);
  license_gate is no longer masked with `|| true`.

## Suggested next work

1. Implement CMN-WF-003 / CMN-DOC-001 (accepted copilot findings, not yet synced).
2. Confirm the next monthly Dependabot `all-dependencies` PR (Insights).
3. Refresh donor digests / drop ignorefile entries before 2026-11-11.
4. Paste Hub Overviews (or widen `DOCKERHUB_TOKEN` to admin) — sync was Forbidden.

## Recent history

- 2026-09-11: accepted copilot ai-reviewer findings filed as CMN-WF-003 and
  CMN-DOC-001 on `feature-rescan-permissions-trivyignore` (not committed; do
  not run live `issues-sync.py` until approved).
- 2026-09-11: `packages: read` on published-image rescans and ci-lint /
  ci-supply-chain scan jobs; zizmor `self-repository` ignored until actionlint
  supports `uses: $/…`; DHI python 3.13 donor digests refreshed (DOCKER-BUILD-006);
  Trivy ignore extended for Go stdlib / x/crypto in donor binaries.
- 2026-08-12: containerdevops `3.0.0` published Alpine `ci-container` on ci-lint
  `4.0.0`; reusable callers **remain** on containerdevops `2.4.0` (no reusable delta).
- 2026-08-12: CMN-IMG-003 / release `4.0.0` — Alpine `ci-lint` owns unsuffixed,
  static Debian shellcheck/gitleaks donors, unify `CMD ["sh"]` (fixes broken Alpine
  `ci-supply-chain` default command), pins → containerdevops `2.4.0`.
- 2026-08-12: #54 bump guardrails past ci-base drop (`5a7ac83…`).
- 2026-08-12: CMN-IMG-001 / CMN-IMG-002 / release `3.0.0` — delete `docker/ci-base`,
  add Alpine `ci-supply-chain` (`-alpine`/`-debian`; Alpine owns unsuffixed),
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

*Last updated: 2026-09-11*
