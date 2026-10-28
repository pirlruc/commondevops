# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `ops/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (public). Image publishes are finished. The owner can set the repo private. Do not change visibility from an agent session. |
| **Branch** | `main` at `2eac235` (PR 238). GitHub Release **5.5.0** is `66f9b4a`. Annotated tags **5.5.1**–**5.5.3** have no Release. **5.5.3** is `c8ab717`. Reusable defaults stay on the pullable 5.3.3 digests. In-repo rescans use the 5.5.0 digests. Do not move `5.4.4`–`5.5.3`. |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, OpenTofu, SOPS, release + `ci-lint` / `ci-supply-chain` / `ci-iac` images |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-lint-image.yml`, `ci-supply-chain-image.yml`, `ci-iac-image.yml`, `scripts/`,
`docker/ci-lint/`, `docker/ci-supply-chain/`, `docker/ci-iac/`. Consumers pin `pirlruc/commondevops@<sha|tag>` and pass
matching `scripts_ref` + `checkout_token`. `common-doc-verify.yml` /
`common-scaffold-verify.yml` ship in 4.1.0; older pins do not have them.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops)
`dd884203c9ffe30e4d4da838cc9e88a888a484a1` (compose GHCR refs from
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
| CMN-TOFU-001 — ci-iac + common-tofu-verify | Done on `feature-image-docs` (release 5.4.0) |
| CMN-SOPS-001 — common-sops-verify, no Age key | Done on `feature-image-docs` (release 5.4.0) |
| CMN-DOC-003 — README rows | Done on `feature-image-docs` |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag **1.13.1** → `1945211ac851c3c0f83694bd4ea53571fdced4ab` |
| github-scaffold submodule | tag **1.10.0** → `1d9901f7e7e5785abb7cac6f5d46e0e8e2023ff8` |
| methodologies (links only; not a submodule) | tag **1.9.1** |
| containerdevops (image callers + security rescan) | tag **6.3.0** → `dd884203c9ffe30e4d4da838cc9e88a888a484a1` |
| actions/checkout | `3d3c42e…` (v7.0.1) |
| `ghcr.io/pirlruc/ci-lint` (debian, unsuffixed) | `5.5.0` index `sha256:5551873fd68cc807611f3feddfdca79c5f73dc8cab87031c8e548cae29e6661a`. Actions amd64 `sha256:4d96a0235459c9e2cc724a724f42008dcdc3294940c57edb8b33b11e38efddba`. |
| `ghcr.io/pirlruc/ci-lint` (alpine) | `5.3.3-alpine` `sha256:bdd9c2ea12ad700da6ebd8426845d883510156a188b741f32ffd9ceb3f43f830` |
| `ghcr.io/pirlruc/ci-supply-chain` (alpine, unsuffixed) | `5.3.3` `sha256:eaa177b7c527ebe54449bb77b39dfd3eb9e7f403c799044a1b6647677a0aba74` |
| `ghcr.io/pirlruc/ci-supply-chain` (debian) | `5.3.3-debian` `sha256:c4319ff77a65c1223f214ca27c545a1bc81da023ea0ee33a697fc817c54c2099` |
| `ghcr.io/pirlruc/ci-iac` | `5.4.1` `sha256:3a25e6c307ebe0e06466e3026b7ed91b1c5a7b24d45382eb986c578fa4cd0a03` |
| Release (reusables) | **5.4.1** is `d03953476f3d5fa1081a0834d9882007ff26dd91`. **5.4.0** is `76b416c74415d27453836ea50fa037990496686b` |
| Release (images) | **5.4.1** republished the three images and moved `latest`. The `ci-lint` and `ci-supply-chain` rows below are the last digests written into the docs (5.3.3), not `latest` |

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
- **Job-container git:** ci-lint and ci-supply-chain do not ship git. The job
  mounts the runner's `/usr/bin/git`, `/usr/lib/git-core`, and the
  libcurl-gnutls closure. `git-remote-https` from git 2.55 fails without
  `libcurl-gnutls.so.4` and `libunistring.so.5`. Do not overlay the image's
  libc or libssl. Sparse checkout of a second repository fails inside that
  container (`ENOENT` on `.git/info/sparse-checkout`); those jobs check out
  the scripts tree in full. Inside the container, `${{ github.workspace }}`
  in a `run` script is the host path; use `$PWD` after the step's working
  directory is the workspace. Do not apt-get install git, and do not publish
  a new image to add it.
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

1. Do not tag `5.4.9` for the PATH fix. pixeldive pins `0932c7bf`, which is past **5.4.8**. Job containers that use a public image set `mount_runner_git: false` and `shell: bash`. Tools copied to `~/.local/bin` are appended to `GITHUB_PATH`. `pip install --user` sets `PIP_BREAK_SYSTEM_PACKAGES`. Hub pages still show the 5.3.3 digests on purpose. The 5.4.4 digests live in the GitHub Release.
2. Hub Overviews update on a push to `main` when `docs/docker-hub*.md` changes, and on `workflow_dispatch`. That calls [container-hub-description](https://github.com/pirlruc/containerdevops/blob/6.3.0/.github/workflows/container-hub-description.yml) and does not republish images. `DOCKERHUB_DESCRIPTION_TOKEN` stays out of image workflows.

## Recent history

- 2026-10-28: The 5.5.0 Debian posture SARIF for ci-lint and ci-supply-chain was uploaded to `refs/heads/main` at `2eac235`. Five of the 38 `trivy-posture-debian` alerts closed as fixed (138, 175, 176, 177, 257). The other 33 are still in the 5.5.0 ci-lint posture and stay open. Supply-chain adds 37 open alerts on the same commit. `trivy-ci-lint` and `trivy-ci-supply-chain` were last analyzed on 2026-10-26 at `4e6f3385` and did not close. Callers stay at `4a7c8c43`. Do not move `5.4.4`–`5.5.3`.
- 2026-10-28: **5.5.3** on `c8ab717` puts reusable defaults back on the 5.3.3 digests. ci-lint and ci-supply-chain 5.5.0 are private, so other repos stay on commondevops `4a7c8c43`. Do not move `5.4.4`–`5.5.3`.
- 2026-10-28: **5.5.0** on `66f9b4a` published the images. **5.5.1** pins the linux/amd64 digests. Do not move `5.4.4`–`5.5.0`.
- 2026-10-27: pull request 234 is the 5.5.0 image refresh (trivy 0.76.1, grype 0.121.0, grant without a forced containerd). The Debian supply-chain build failed once on a proxy stream error. Do not tag 5.5.0 until that build is green. Do not move `5.4.4`–`5.4.8`.
- 2026-10-24: **5.4.8** on `32075ce` (PR 231) sets bash shells and an optional git mount. PR 232 merged as `0932c7bf` and adds `GITHUB_PATH` plus `PIP_BREAK_SYSTEM_PACKAGES`. No tag on `0932c7bf`. No GitHub Release after 5.4.4, so the images were not republished. Do not move `5.4.4`–`5.4.8`.
- 2026-10-23: Dismissed Scorecard Token-Permissions alerts 318, 312, and 314 under CI-042. Each token's only write scope is `security-events: write` for the dedicated SARIF upload job. Review 2026-12-31. Scan jobs that upload SARIF themselves stay open.
- 2026-10-23: **5.4.3** — guardrails 1.13.1. CMN-PRIV-001 job-container credentials. Hub Overview push when `docs/docker-hub*.md` changes. Tag only. No GitHub Release.
- 2026-10-23: Hub Overview dispatch for `ci-lint`, `ci-supply-chain`, and `ci-iac`. It does not republish images.
- 2026-10-23: **5.4.2** — record the `ci-iac` digest from the 5.4.1 release publish (`sha256:3a25e6c3…`). Tag only, so the image workflow does not publish again.
- 2026-10-23: **5.4.1** — image callers pin containerdevops **6.3.0**. The release publish moved `ci-iac` `latest`.
- 2026-10-23: **5.4.0** — `ci-iac` (OpenTofu, tflint, sops, age, ansible-lint), `common-tofu-verify`, `common-sops-verify`, `common-pins-verify`, `common-threshold-drift`. Vendored `license_deny_list` matches guardrails 1.12.0.
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

*Last updated: 2026-10-28 (5.5.0 Debian posture uploaded to main; callers stay at 4a7c8c43)*
