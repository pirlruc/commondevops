# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `ops/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (PRIVATE) |
| **Branch** | `main` → tag **5.3.2** (guardrails pin; images stay **5.3.0**) |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, release + `ci-lint` / `ci-supply-chain` images |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-lint-image.yml`, `ci-supply-chain-image.yml`, `scripts/`, `docker/ci-lint/`,
`docker/ci-supply-chain/`. Consumers pin `pirlruc/commondevops@<sha|tag>` and pass
matching `scripts_ref` + `checkout_token`. `common-doc-verify.yml` /
`common-scaffold-verify.yml` ship in 4.1.0; older pins do not have them.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops)
`2ad052e69d2587cdaf8ccac59b9dae5c60f5560b` (compose GHCR refs from
`handoff_package` + `digest`; `flavor: latest=false`). Do not pin 5.0.0
(`f5a3a632…`) — job outputs from the handoff `always()` step were empty.
`common-doc-verify.yml` / `common-scaffold-verify.yml` shipped in **4.1.0**
(`dcd9ca1c4eb8faedba170fef5dbecc61d7b284b3`) and remain. Callers must re-pin
after **5.1.2**; `scripts_ref` must match. Cross-repo callers need
`COMMONDEVOPS_READ_TOKEN` — `GITHUB_TOKEN` cannot clone this private repo.

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
| CMN-WF-003 — Alpine check-ci-docker.sh POSIX sh | Done (`4.1.0`) |
| CMN-DOC-001 — Caller-contract docs | Done (`4.1.0`); T1 was already 2.4.4 |
| CMN-PIN-001 — guardrails 1.6.0 pin | Done (this wave) |
| CMN-WF-004 — single POSIX runner via scripts_ref | Done (this wave) |
| CMN-RESCAN-001 — rescan caller recipe | Done (this wave) |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag **1.10.0** → `e2db476f…` |
| github-scaffold submodule | tag **1.8.0** → `ac9059fd…` |
| methodologies (links only; not a submodule) | tag **1.8.0** |
| containerdevops (image callers + security rescan) | `2ad052e69d2587cdaf8ccac59b9dae5c60f5560b` (feature-ops-hardening; not tagged) |
| actions/checkout | `3d3c42e…` (v7.0.1) |
| `ghcr.io/pirlruc/ci-lint` (debian, unsuffixed) | `5.3.0` `sha256:38b9afe1086295b011e69d092cf06ee133c17b9784e82a19826db7432ae35c45` (`latest` == debian) |
| `ghcr.io/pirlruc/ci-lint` (alpine) | `5.3.0-alpine` `sha256:c55c8f74f2d99d7725cd5a2f785a3782b37d92939baa482a6774308cc5846bf9` |
| `ghcr.io/pirlruc/ci-supply-chain` (alpine, unsuffixed) | `5.3.0` `sha256:71ad1ca2f404147d00351b492d051c1213dacffeb961fcd96f2053e7715ab17e` |
| `ghcr.io/pirlruc/ci-supply-chain` (debian) | `5.3.0-debian` `sha256:6706b44d46e252537af3ad77b797c6c880f98afa2059e954cbf0d597ff054900` |
| Release (reusables) | **5.3.0** |
| Release (images) | **5.3.0** |

## Local image sizes / posture (2026-08-12, `du -sxm /`)

| Image | Rootfs | Posture (os+library, no ignore) | Notes |
|-------|--------|----------------------------------|-------|
| ci-lint debian | ~545 MB | 28 HIGH / 4 CRITICAL (20 OS) | `size_class: ci_toolchain` |
| ci-lint alpine | ~752 MB | 12 HIGH / 0 CRITICAL (0 OS) | **owns unsuffixed** |
| ci-supply-chain debian | ~575 MB | — | `size_class: ci_toolchain` |
| ci-supply-chain alpine | ~722 MB | — | owns unsuffixed |

## Commands

```bash
sh scripts/check-ci-local.sh
COMMONDEVOPS_CI_IMAGE=ci-lint:alpine-local COMMONDEVOPS_DOCKER_STEPS="actionlint shellcheck hadolint zizmor yamllint" \
  sh scripts/check-ci-docker.sh
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

- **Size class:** CI toolchain images pass `size_class: ci_toolchain` so
  container-build reads `ci_image_max_size_mb` (2000, DOCKER-PERF-002). Do not
  re-record DOCKER-PERF-001 deviations for ci-lint / ci-supply-chain.
  REL-CHG-001 is closed by root `CHANGELOG.md`. Unsigned private publish is
  recorded as SC-SIGN-001 / SC-PROV-001.
- **Caller permissions:** reusable workflows cannot escalate. Build callers must
  grant `packages: write` (ephemeral GHCR handoff) or the run dies at
  **startup_failure**. Scan callers of a `ghcr.io/` image must grant
  `packages: read` and compose
  `ghcr.io/<owner>/<handoff_package>@<digest>` (do not pass `image_ref`:
  Actions strips it when `DOCKERHUB_USERNAME` equals the owner).
  Do **not** delete published GHCR versions; PR cleanup may delete `ci-run-*`
  only when that is the version's sole tag.
- **ignorefile:** blocking scans pass per-image files under `docker/ci-*/`. Posture
  scans must set `ignorefile: none` (containerdevops ≥ 2.2.0) or the caller-root
  fallback silently filters findings. Root `.trivyignore.yaml` was removed.
- **Variant jobs:** parallel debian/alpine builds need unique `artifact_name`,
  `results_artifact`, and `sarif_category` (containerdevops ≥ 2.3.0).
- **Debian owns unsuffixed `ci-lint` tags.** Alpine ci-lint has no semgrep
  (no musllinux wheel). Parallel calls of `common-secrets-sast` or
  `common-infra-lint` in one run must pass a distinct `concurrency_suffix`
  or GitHub cancels the extras.
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
- **Quota (2026-09-15):** leftover `container-image-*` Actions artifacts were
  deleted. Image builds inherit containerdevops BuildKit
  `cache-to: type=gha,mode=min`. Do **not** delete published GHCR/Hub tags or
  bulk-delete GHA cache entries.
- **check-ci-local.sh:** `--no-docker` fails when tools are missing (no silent pass);
  license_gate is no longer masked with `|| true`.

## Suggested next work

1. Homelab gap epics are filed and not implemented: CMN-TOFU-001 (tofu/tflint workflow and ci-lint tools), CMN-SOPS-001 (encryption check, no Age key in CI), CMN-DOC-003 (README rows for common-ansible-verify and common-token-audit).
2. CMN-CVE-001 is done. actionlint and grant were rebuilt on Go 1.26.8 in
   5.3.0. Module CVEs stay ignored until upstream ships.
3. Confirm the next monthly Dependabot `all-dependencies` PR (Insights).
   The 2026-10-02 group was closed because it jumped Go 1.26 to 1.27.

## Recent history

- 2026-10-02: Rebuild actionlint and grant on DHI Go 1.26.8; hashed ci-lint
  lock; retire SC-PROV-001; `common-token-audit.yml`. Images not republished
  until the next GitHub Release.
- 2026-10-02: tool lock is semgrep **1.179.0**, PyJWT **2.15.1**, mcp 1.29.0,
  urllib3 2.8.0. ci-lint Dockerfiles install those pins directly; the PyJWT
  override file is gone (CMN-CVE-001-T3). Images are not republished yet.
- 2026-10-01: **5.2.6** (tag-only) — containerdevops **6.1.0**
  (`edef9c84…`). The tool lock was semgrep 1.178.0, mcp 1.29.0, urllib3 2.8.0.
  The sweep deletes pull and tag Actions caches. Images are not republished.
- 2026-10-01: **5.2.5** (tag-only) — write 5.2.4 alpine/debian digests.
  Debian OpenSSL is `deb13u3` in that publish. No GitHub Release.
- 2026-10-01: **5.2.4** — DHI syft 1.52.0, grype 0.119.0, trivy 0.74.0, and
  gitleaks (still 8.30.1, rebuilt, binary now at `/usr/bin/gitleaks`) drop
  fixable HIGH findings. grant 0.6.8 and actionlint 1.7.12 stay. Debian
  Python base now ships OpenSSL `deb13u3`. Image digests are written
  back after the GitHub Release publishes.
- 2026-09-30: guardrails **1.8.0** / scaffold **1.7.0**. Methodology decision
  links cite **1.6.0** (no methodologies submodule). Synced scaffold templates.
- 2026-09-15: **5.1.2** (tag-only) — write 5.1.1 alpine/debian Hub digests
  (`ci-lint` `35a82a43…` / `6834b695…`, `ci-supply-chain` `10c82137…` /
  `ad653b38…`). Hub `latest` == `5.1.1` alpine.
- 2026-09-15: **5.1.1** — containerdevops 5.0.2 nested pin, scheduled rescans
  off `ci-lint:4.0.0` / `ci-supply-chain:3.0.0` onto 5.1.0 Hub digests,
  Hub/Packages target 5.1.1. Hub `latest` == `latest-alpine` (flavor fix);
  monthly rebuild on the 15th moved `latest` off the 5.1.0 SemVer tag — pin
  digests. GHCR pulls 403 without `read:packages`; Hub digests used for
  writeback.
- 2026-09-15: Quota sweep — leftover `container-image-*` artifacts deleted.
  GHA cache remains `mode=min` via containerdevops (no GHCR published-tag delete).
- 2026-09-14: **5.1.0** — re-pin containerdevops 5.0.1 GHCR handoff, CHANGELOG,
  SC-SIGN/SC-PROV, zizmor config parity, Alpine secrets scan, threshold-driven
  supply-chain severity.
- 2026-09-14: Tagged **5.0.0** + GitHub Release (`bcddb5db…`, #88).
- 2026-09-14: CMN-PIN-001 / CMN-WF-004 / CMN-RESCAN-001 — guardrails `1.6.0` +
  scaffold `1.5.0`; containerdevops `4.0.0` + `size_class: ci_toolchain`;
  fail-closed threshold reader; collect-then-fail; digest-pinned rescans;
  POSIX `scripts_ref` recipe; REL-CHG-001 deviation.
- 2026-09-11: Filed CMN-WF-004 (promote POSIX `check-ci-docker.sh` via `scripts_ref`)
  and CMN-RESCAN-001 (`container-published-rescan` caller recipe). Tag `4.1.0` is
  current. Doc-repo `common-doc-verify` adoption is blocked on `COMMONDEVOPS_READ_TOKEN`.
- 2026-09-11: CMN-WF-003 POSIX `check-ci-docker.sh` + shared `scripts/ci-steps.sh`;
  CMN-DOC-001 permission matrix and `ghcr-package-visibility` link; filed
  CMN-PIN-001 (stale non-tag guardrails pin vs 1.6.0). Digest-pinned default
  `COMMONDEVOPS_CI_IMAGE`.
- 2026-09-11: Wave 4 — `devops-security.yml` published rescans call
  `container-published-rescan.yml@3.0.2` (`3607bf0…`) with unique artifacts.
  Image CI stays on `container-scan.yml` at the same SHA.
- 2026-09-11: Wave 4 — add reusable `common-doc-verify.yml` (shellcheck/ruff/YAML/link
  lint) and `common-scaffold-verify.yml` (issues-sync `--validate-only` + SCAFFOLD_REF).
  Doc-repo callers and `GUARDRAILS_READ_TOKEN` wiring are follow-up. Do not treat
  older consumer pins (`74695e8`, `4fd8392`, `e4e902e`) as having these files.
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

*Last updated: 2026-10-05 (homelab gap epics filed, not implemented)*
