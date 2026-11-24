# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `ops/commondevops/` |
| **Remote** | <https://github.com/pirlruc/commondevops> (public). Image publishes are finished. The owner can set the repo private. Do not change visibility from an agent session. |
| **Branch** | `main`. Published tip is **v6.10.0** after this release. Images stay **6.8.0**. Guardrails 1.17.1 and scaffold 1.14.2. pytest is hash-locked. semgrep still pins mcp 1.29.0, opentelemetry-api 1.37.0, and wcmatch 8.5.2 (CMN-MCP-001). |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, OpenTofu, SOPS, release + `ci-lint` / `ci-supply-chain` / `ci-iac` images |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `devops-ci.yml`, `devops-security.yml`,
`ci-lint-image.yml`, `ci-supply-chain-image.yml`, `ci-iac-image.yml`, `scripts/`,
`docker/ci-lint/`, `docker/ci-supply-chain/`, `docker/ci-iac/`. Consumers pin `pirlruc/commondevops@<sha|tag>` and pass
matching `scripts_ref` + `checkout_token`. `common-doc-verify.yml` /
`common-scaffold-verify.yml` ship in 4.1.0; older pins do not have them.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops)
**6.8.0** (`ae9dbee9e4537bd3a0b533de3bad011cb44b201e`). Callers compose GHCR
refs from `handoff_package` + `digest`.
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
| CMN-LINT-003 — doc-verify lint defaults | Done (`6.0.0`) |
| CMN-RECON-002 — done-vs-open on the default branch | Done (`6.0.0`) |
| CMN-TOK-001 — no Dependabot secret as checkout_token | Done (`6.0.0`) |
| CMN-REL-004 — skip an image release with no `docker/` diff | Done (`6.0.0`) |
| CMN-ENV-001 — publish environment and SARIF switch | Done (`6.1.0`) |
| CMN-DEP-001 — dependency review workflow | Done (`6.2.0`) |
| CMN-BUF-001 — buf lint and breaking | Done (`6.3.0`) |
| CMN-BUF-002 — push compares against a SHA | Done (`6.4.0`) |
| CMN-CRED-001 — keep GHCR credentials | Done (`6.4.0`) |
| CMN-SWIFT-001 — Swift package CI | Done (`6.4.0`) |
| CMN-PERM-001 — no write scope on check workflows | Done (this wave; SARIF upload stays on supply-chain and scorecard) |
| CMN-RUN-001 — `runs_on` on documentation callers | Done (already on the five workflows; recorded in `docs/workflows.md`) |
| CMN-HYG-001 — doc hygiene check | Done (this wave; tag with 6.7.0) |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag **1.17.0** → `9a17ebb269a5ab02899570dd3e40fb72e50ad762` |
| github-scaffold submodule | tag **1.14.0** → `da8942edf17a0d2736d297c90338fd78b7ec31fb` |
| methodologies (links only; not a submodule) | tag **1.12.2** |
| containerdevops (image callers + security rescan) | tag **6.8.0** → `ae9dbee9e4537bd3a0b533de3bad011cb44b201e` |
| actions/checkout | `3d3c42e…` (v7.0.1) |
| `ghcr.io/pirlruc/ci-lint` (debian, unsuffixed) | `6.10.1` index `sha256:fe8451208cea28fc7cd2953d289a39620379e9e762ca8e50563de2c53a0ec9b5`. Actions amd64 `sha256:9e3fa55713747600a8088912d9fd92366eeaf63e01902c9de3d550a0edde58a6`. |
| `ghcr.io/pirlruc/ci-lint` (alpine) | `6.8.0-alpine` index `sha256:c55ed2f274e1329e0feffe1a5055bdf5859e5c16fc033bde7b61d59e173582e9`. Actions amd64 `sha256:adaa142df825e1532a799f57004d969fb2899a41d6c2b768ed06c6ded1099007`. |
| `ghcr.io/pirlruc/ci-supply-chain` (alpine, unsuffixed) | `6.10.1` index `sha256:5c828d2345c1d81d884edc060c7e67859793b0767a3cb20bbd47889c4fbad7ff`. Actions amd64 `sha256:3cd91af0e57827678edbe04d967eb515dde12f9dc532f990829b320f5db07261`. |
| `ghcr.io/pirlruc/ci-supply-chain` (debian) | `6.10.1-debian` index `sha256:6e88a5697e8a9663910e22a63d873279947f388b0d968307570362e476bafe7e`. Actions amd64 `sha256:4201515dd229bba26a4b275370f47f4c6ae7df52778408b0277336ee38c810ef`. |
| `ghcr.io/pirlruc/ci-iac` | `6.10.1` index `sha256:5f5bbed1cd03e6b8e219fe79d16f3571aebf3959157faefba46c6c0d4199535e`. Actions amd64 `sha256:828cbe098f1f90347a2702ad08dc21aa7d47e60e31084dcc290ece80e660f636`. |
| Release (reusables) | **v6.9.1** moves image callers and the rescan onto containerdevops 6.8.0. **v6.9.0** is `5d8b83da2f8f0c0c1bd894ef920619fe127c033e`. **v6.8.0** is `4de58c7449029c2022301c1654d1aa2da9f7bcec`. |
| Release (images) | **6.8.0** published the three images. v6.9.0 does not republish. |

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

- **Release digest append:** `scripts/append-release-digests.sh` logs in to GHCR when `GH_TOKEN` is set. Anonymous `imagetools inspect` of `ci-lint` returns 401. Do not pass the index digest to awk as `-v index=`; gawk reserves `index`. `common-release-digests` checks out `pirlruc/commondevops` at `scripts_ref` (CI-034). `github.workflow_sha` is the caller, so it is not a checkout ref. A tag `v6.7.0` is inspected as `6.7.0` because the publish tags drop the leading `v`. `.grype.yaml` ignores GHSA-qx49-fqc8-xw99, the same mcp 1.29.0 CVE already in `.trivyignore`. 6.0.1 did not republish, so the 6.0.0 Release carries the 6.0.0 `ci-lint` digests. `ci-supply-chain` and `ci-iac` 6.0.0 scans failed, so those tags were not published.
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
  `release_artifact` downloads an artifact uploaded earlier in the **same**
  run (`needs:` the build job). It is not a previous run. `release_files`
  filters by path or basename. Checksums are regenerated; do not ship a
  hand-written `.sha256` inside the artifact.
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

1. CMN-MCP-001 stays open until semgrep allows mcp 1.30.0. Do not recompile the ci-lint lock past that pin.
2. CMN-OPS-CI-001 is a reusable for the self-CI stack that nodedevops and rustdevops copy. It is not built yet.
3. Hub Overviews update on a push to `main` when `docs/docker-hub*.md` changes, and on `workflow_dispatch`. That calls containerdevops `container-hub-description` and does not republish images.

## Recent history

- 2026-11-24: **v6.9.1** points image workflows and the scheduled rescan at containerdevops 6.8.0. `scripts/fetch-verified.sh` is the download helper (CI-054).
- 2026-11-23: **v6.8.0** pins guardrails 1.17.0, scaffold 1.14.0, and containerdevops 6.7.0. ci-supply-chain builds containerd 2.4.2. pytest is hash-locked. semgrep still requires mcp 1.29.0.
- 2026-11-15: reusable workflows the homelab callers use accept `runs_on` (JSON, default `"ubuntu-24.04"`). Signing moved to `common-release-sign.yml` so `common-release.yml` requests `contents: write` only. Still not tagged. The 2026-11-14 tofu, sops, and ansible inputs are in the same unreleased 6.5.0.
- 2026-11-14: common-tofu-verify and common-sops-verify accept container_username and container_token. common-sops-verify host_mode runs the ciphertext check without an image pull. Ciphertext must be AES256_GCM and must not contain a private key block. common-secrets-sast uploads redacted JSON. common-ansible-verify accepts playbooks and public_submodules. common-tofu-verify accepts test_directory. Not tagged yet.
- 2026-11-07: **6.0.1** runs the missing-pack check from the `scripts_ref` checkout. **6.0.0** turns doc-verify shfmt and markdownlint on by default. Guardrails 1.15.0, scaffold 1.12.0. semgrep stays on mcp 1.29.0. Image workflows still call containerdevops 6.3.5.
- 2026-11-01: **5.8.0** makes `common-release` `sign: true` run keyless `cosign sign-blob` and `actions/attest-build-provenance`. New `environment` input. No image republish. Do not move `5.7.0` or `5.6.2`.
- 2026-10-31: **5.7.0** adds `release_artifact` and `release_files` to `common-release`. No image republish. Do not move `5.6.2`.
- 2026-10-28: **5.6.1** published ci-lint, ci-supply-chain, and ci-iac with go-jose/v4 4.1.6. Tag **5.6.0** was not moved. **5.6.2** pins the linux/amd64 manifests in the reusable defaults, the rescan, and the Hub/GHCR pages. No second publish.
- 2026-10-28: Job containers log in to GHCR with `github.token`. Image scans use separate SARIF categories. Image workflows pin containerdevops 6.3.5. Lint callers grant `packages: read`. Scan callers grant `actions: read`.
- 2026-10-28: `common-doc-verify` no longer skips Dependabot. Callers pass `DEPENDABOT_GITHUB_TOKEN` on those pulls and `COMMONDEVOPS_READ_TOKEN` on Actions runs. grant, syft, grype, trivy, sops, tofu, and tflint Docker builds request go-jose/v4 4.1.6. tflint v0.65.0 is rebuilt from `502b6a38`. No tag and no image republish, so the 5.5.0 rescan still scans the published binaries.
- 2026-10-28: The 5.5.0 Debian posture SARIF for ci-lint and ci-supply-chain was uploaded to `refs/heads/main` at `2eac235`. Five of the 38 `trivy-posture-debian` alerts closed as fixed (138, 175, 176, 177, 257). The other 33 are still in the 5.5.0 ci-lint posture and stay open. Supply-chain adds 37 open alerts on the same commit. `trivy-ci-lint` and `trivy-ci-supply-chain` were last analyzed on 2026-10-26 at `4e6f3385` and did not close. Do not move `5.4.4`–`5.5.3`.
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

*Last updated: 2026-11-24 — v6.10.2. The job-container default is ci-lint 6.10.1 linux/amd64 `9e3fa557`, which has gzip and bash. CMN-IMG-004 stays open.*

*Last updated: 2026-11-24 — v6.9.0. Scorecard falls back to github.token. Rescans pin the 6.8.0 images. Posture categories refresh on the default branch.*

*Last updated: 2026-11-23 — v6.8.0. Guardrails 1.17.0. Scaffold 1.14.0. DOCKER-SEC-001 records CVE-2026-115563 until semgrep allows mcp 1.30.0. Review 2027-02-23.*

*Last updated: 2026-11-24 — v6.9.1. Image callers and the scheduled rescan pin containerdevops 6.8.0. Download helper is `scripts/fetch-verified.sh`.*

*Last updated: 2026-11-23 — v6.8.0. Guardrails 1.17.0. Scaffold 1.14.0. containerdevops 6.7.0. containerd 2.4.2.*

*Last updated: 2026-11-23 — 6.7.0 adds the doc hygiene check. CMN-PERM-001 and CMN-RUN-001 are recorded.*
*Last updated: 2026-11-20 — digest job checks out commondevops at scripts_ref and strips a leading v from image tags.*
*Last updated: 2026-11-15 — `runs_on` on the homelab-facing reusables. `common-release-sign.yml` holds id-token and attestations. Not tagged.*
*Last updated: 2026-11-18 — 6.4.0 is `f7658926` and 6.4.1 is `8934d843`. 6.4.1 only splits the semgrep config list. The ci-lint image was not rebuilt. Do not move `5.4.4` through `6.5.0` or `v6.5.0`.*

*Last updated: 2026-11-08 — 6.1.1. Image jobs accept container_token and container_username so another account's repository can pull a personal-account package.*

*Last updated: 2026-11-07 — 6.0.1. The pack check uses the scripts_ref checkout. Guardrails 1.15.0. Scaffold 1.12.0.*

*Last updated: 2026-11-07 — Scorecard Code-Review, Fuzzing, CII-Best-Practices, and Maintained stay open. See docs/scorecard-open-checks.md.*

*Last updated: 2026-11-07 — REL-PUB-005 append logs in to GHCR. The 6.0.0 Release lists the published ci-lint digests.*
