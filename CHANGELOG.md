# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Fixed

- `common-doc-verify` runs on Dependabot pull requests. Cross-repo callers
  pass `DEPENDABOT_GITHUB_TOKEN` as `checkout_token`. Actions runs pass
  `COMMONDEVOPS_READ_TOKEN`. Same-repo runs use `github.token`.
- grant, syft, grype, trivy, sops, tofu, and tflint builds request
  `github.com/go-jose/go-jose/v4@v4.1.6` (CVE-2026-116587). tflint v0.65.0
  is rebuilt from `502b6a38` because the upstream zip embeds v4.1.4.
  Tags `5.4.4` through `5.5.3` stay put. Images are not republished, so
  the 5.5.0 rescans still see the published binaries.

## [5.5.3] - 2026-10-28

### Fixed

- Reusable defaults are the 5.3.3 digests callers already pull.
  The 5.4.4 and 5.5.0 digests return `manifest unknown` from other
  repositories. In-repo rescans still use the 5.5.0 digests.

## [5.5.2] - 2026-10-28

### Fixed

- Reusable job defaults stay on the 5.4.4 digests. ci-lint and
  ci-supply-chain 5.5.0 are private, and other repositories get
  `manifest unknown` when they pull those digests. The in-repo
  rescan still uses the 5.5.0 digests.

## [5.5.1] - 2026-10-27

### Changed

- Job containers and the published rescans use the 5.5.0 linux/amd64
  digests. ci-lint `sha256:4d96a0235459c9e2cc724a724f42008dcdc3294940c57edb8b33b11e38efddba`.
  ci-supply-chain Debian `sha256:b43eb3a99bc4c2003eb64ef5d6d0cdcbbc22d78904aa6b24d76ad0426035a7f6`.
  ci-supply-chain Alpine `sha256:418d50c4ac06a0b913f00f63f228f8df219584b13f3d55502b8f94a14c410b87`.
  ci-iac `sha256:48976387ca78d6dea75d9d5a3ab26be0e738f9bb2d946de31c4ab4f7c433165f`.
- Hub latest rows match the 5.5.0 indexes. The 5.5.0 release uploaded
  fresh image posture. Older tag alerts stay until they are dismissed.

## [5.5.0] - 2026-10-27

### Changed

- ci-lint, ci-supply-chain, and ci-iac build on Go 1.27. trivy is 0.76.1
  and grype is 0.121.0. grant's build adds x/crypto 0.57.0 and x/mod 0.41.0.
- semgrep stays on mcp 1.29.0. The 2.x lock from Dependabot does not install.
- markdownlint-cli2 is 0.24.0. The high and moderate npm alerts clear.
  Four low alerts remain inside that tool.
- Published rescans use the 5.4.4 linux/amd64 images, including ci-iac,
  through containerdevops 6.3.5. Callers grant `actions: read`.
- A called reusable no longer joins the dispatch concurrency group.
- README names github-scaffold 1.10.2. The guardrail approval link is
  methodologies 1.9.2.

### Fixed

- Tools installed into `~/.local/bin` on a public job image are added to
  `GITHUB_PATH`, so later steps can run them. `pip install --user` sets
  `PIP_BREAK_SYSTEM_PACKAGES` because Ubuntu 24.04 pip is externally
  managed.
- Job containers for infra lint, secrets, and supply-chain authenticate
  with `checkout_token` when a caller passes one. The caller's
  `GITHUB_TOKEN` cannot pull this repo's private images. A caller that
  still cannot pull them passes a public `container_image`.
  `mount_runner_git` stays on for the private image, which has no git,
  and off when the image already has bash and git. Job `run` steps
  use `bash`, because a container's default shell is `sh`. The default
  image stays the private linux/amd64 digest.
- `common-infra-lint` and `common-secrets-sast` pin the 5.4.4
  ci-lint linux/amd64 digest. `common-supply-chain` pins the 5.4.4
  Debian linux/amd64 digest, because the Alpine image has no bash.
  A `container:` image must be that manifest. The 5.3.3 digests those
  workflows still named are no longer on GHCR.

## [5.4.4] - 2026-10-23

### Changed

- Self-CI runs shfmt (SHELL-LINT-002). Scripts under `scripts/` are
  formatted with shfmt's default (tabs).
- Dependabot pip entries for `/scripts`, `/docker/ci-lint`, and
  `/docker/ci-iac` stay off the git registry. Attaching `github-private`
  makes the pip graph update fail with `unexpected_external_code`.
- Hub and GHCR examples pin ci-lint and ci-supply-chain 5.3.3 digests.
  ci-iac is documented as published with 5.4.1.
- grype and grant Trivy ignores are re-triaged to 2026-11-22. Grant has
  no release after 0.6.8. Grype 0.121.0 and Trivy 0.76.1 exist upstream
  and belong on the next image cut, not a workflow-only tag.
- github-scaffold submodule is 1.10.2. Synced agent files were already
  current, so the tree diff is the gitlink.
- Refresh DHI base digests in the ci-lint, ci-supply-chain, and ci-iac
  Dockerfiles. The previous python digest was past the 30-day age gate
  (DOCKER-BUILD-006). This release republishes the images. Grype and Trivy
  stay on the binaries already in the image until the next cut.
- CI-032 records the active default-branch ruleset. The repository still
  returns to private, where that ruleset cannot be enforced.

## [5.4.3] - 2026-10-23

### Changed

- Pin guardrails **1.13.1** (`1945211a`). 1.13.0 adds the Kotlin ABI check.
  There is no Kotlin consumer here. 1.13.1 only moves common-doc-verify to
  the 5.4.1 SHA this repo already tags.
- `common-infra-lint`, `common-secrets-sast`, and `common-supply-chain` pull
  private `ghcr.io/pirlruc` job containers with `packages: read` and
  `container.credentials` (CMN-PRIV-001). A caller of those workflows grants
  `packages: read`. The published images have no git, so the job mounts the
  runner's git and the libcurl-gnutls libraries `git-remote-https` needs.
  The script checkout is a full tree; sparse checkout fails in that container.
  OpenTofu and SOPS stay on the runner
  and log in with `docker`, because those jobs need the Docker daemon.
- Hub Overviews update on a push to `main` when `docs/docker-hub*.md`
  changes. That path does not publish an image.

## [5.4.2] - 2026-10-23

### Changed

- Record the `ci-iac` digest from the 5.4.1 release publish. `latest` moved.

## [5.4.1] - 2026-10-23

### Changed

- Image callers pin containerdevops **6.3.0**.
- Record the published `ci-iac` 5.4.0 digest in the Hub and Packages docs.
- `common-token-audit` accepts `containerdevops_token` so a caller can audit
  `CONTAINERDEVOPS_READ_TOKEN` without a Scorecard PAT.

## [5.4.0] - 2026-10-23

### Added

- `ci-iac` image (Debian) with OpenTofu 1.13.2, tflint 0.65.0, sops 3.13.3,
  age 1.3.2, and ansible-lint 26.10.1. These tools stay off `ci-lint`.
- `common-tofu-verify.yml` and `common-sops-verify.yml` run from that image.
  The SOPS job does not receive an Age private key and does not decrypt.
- `common-pins-verify.yml` and `common-threshold-drift.yml`.

### Changed

- Vendored supply-chain `license_deny_list` matches guardrails 1.12.0.
- README lists `common-ansible-verify` and `common-token-audit`.

## [5.3.4] - 2026-10-12

### Fixed

- `common-scaffold-verify` requests `issues: read` so the done-versus-open
  check can list issues. Callers that only granted `contents: read` got
  HTTP 403 from that step.

## [5.3.3] - 2026-10-06

### Fixed

- `common-secrets-sast` and `common-supply-chain` grant, at workflow level,
  the permissions their jobs request. An empty set made every caller that
  nests them fail at startup with zero jobs.

### Changed

- Close CMN-CVE-001. actionlint and grant were rebuilt on Go 1.26.8 in 5.3.0.
  Module CVEs stay ignored until upstream ships.

## [5.3.2] - 2026-10-02

### Changed

- Pin guardrails **1.10.0**. Retire SC-DEP-003: the 1.10.0 carve-out covers
  a Dependabot ignore that holds Python at the PY-RUN-003 pin until 2027-04.

## [5.3.1] - 2026-10-02

### Changed

- Record the published 5.3.0 image digests. Debian owns unsuffixed
  `ci-lint` tags. Alpine still owns unsuffixed `ci-supply-chain` tags.

## [5.3.0] - 2026-10-02

### Changed

- Recompile `scripts/requirements.txt` from semgrep 1.179.0. That release
  requires PyJWT >= 2.15, so the lock is now PyJWT 2.15.1 (CMN-CVE-001-T3).
  mcp stays 1.29.0 and urllib3 stays 2.8.0. ci-lint no longer overrides
  PyJWT or urllib3 at image build time.
- Debian owns unsuffixed `ci-lint` tags. semgrep 1.179.0 has no musllinux
  wheel, so the Alpine variant ships zizmor and yamllint but not semgrep.
- Rebuild actionlint v1.7.12 and grant v0.6.8 from their release commits on
  DHI Go 1.26.8. Stdlib HIGH findings clear. Grant module CVEs stay ignored
  with `expired_at: 2026-11-01` (amended CMN-CVE-001). hadolint is 2.15.1.
  ci-lint Python tools install from a hashed lock (zizmor 1.30.1, yamllint
  1.38.0).
- Image callers pin containerdevops `2ad052e69d2587cdaf8ccac59b9dae5c60f5560b`
  (provenance `mode=max` and sbom on without `sign`). SC-PROV-001 is retired.
- Strip setuid and setgid bits in the final image. Debian ci-lint ships
  `/usr/sbin/unix_chkpwd` setuid, which failed the structure test.
- `common-token-audit.yml` checks PAT expiry (90 days, warn at 7). Scaffold
  verify installs PyYAML from a hashed lock. Ansible verify requires
  `--hash` lines. Reusable workflows set concurrency that cancels only on
  `workflow_dispatch`. `common-secrets-sast` and `common-infra-lint` take
  `concurrency_suffix` so several calls in one run do not share a group.

## [5.2.6] - 2026-10-01

### Changed

- Image callers pin containerdevops **6.1.0**
  (`edef9c8413363c46dcb276f5188a033d9fc6fd4e`). That release writes the
  BuildKit cache only on the default branch.
- `scripts/requirements.txt` is recompiled from semgrep 1.178.0, which pins
  mcp 1.29.0, plus urllib3 2.8.0. PyJWT stays 2.13.0 because semgrep declares
  `pyjwt~=2.13.0`; 2.14.0 does not install beside it. The image still overrides
  PyJWT at build time. CMN-CVE-001 tracks the lock bump.
- The artifact sweep deletes Actions caches on pull-request and tag refs.
  Tag only. No GitHub Release, so the images are not republished.

## [5.2.5] - 2026-10-01

### Changed

- Write 5.2.4 alpine and debian digests into rescan, Hub/Packages pages, and
  `check-ci-docker.sh`. Tag only. No GitHub Release, so the images are not
  republished.

## [5.2.4] - 2026-10-01

### Changed

- Refresh DHI syft 1.52.0, grype 0.119.0, trivy 0.74.0, and gitleaks donors.
  Those binaries are built with Go 1.26.8 and drop their fixable HIGH findings.
  grant 0.6.8 and actionlint 1.7.12 are still the latest releases.
- Pin the Debian DHI Python base that ships OpenSSL `3.5.7-1~deb13u3`.

## [5.2.3] - 2026-09-30

### Changed

- Write 5.2.2 alpine and debian digests into rescan, Hub/Packages pages, and
  `check-ci-docker.sh`. Tag only. No GitHub Release, so the images are not
  republished.


## [5.2.2] - 2026-09-30

### Changed

- Refresh the DHI Python 3.13 base digests. The Alpine digest has no HIGH or
  CRITICAL OS findings, which clears expat CVE-2026-93990. Debian openssl
  HIGH remains: the newest DHI digest still does not ship deb13u3.

## [5.2.1] - 2026-09-30

### Changed

- Write 5.2.0 alpine and debian digests into rescan, Hub/Packages pages, and
  `check-ci-docker.sh`. Tag only. No GitHub Release, so the images are not
  republished.


## [5.2.0] - 2026-09-30

### Added

- `common-infra-lint` reads `shellcheck_failure_threshold` and
  `hadolint_failure_threshold` and fails closed when the key is missing.
  `run_shfmt` runs `shfmt --diff` (off by default).
- `common-doc-verify` can run markdownlint-cli2 and lychee. YAML and link
  scripts fall back to `.github/scaffold/scripts/`.
- `common-scaffold-verify` runs on Dependabot pull requests. The done-vs-open
  lookup is skipped there and is token-optional otherwise.
- `common-ansible-verify` for yamllint, ansible-lint, and Molecule.
- `semgrep_config` on `common-secrets-sast` (default `auto`).
- Deviations CI-032, REL-PUB-004, and SC-DEP-003 (Python stays on 3.13 until
  2027-04).

### Changed

- `docs/guardrails` tag **1.9.0** (`16a2c95c…`); `.github/scaffold` tag **1.8.0**
  (`ac9059fd…`). Decision links cite methodologies **1.8.0**.
- CI-024 uses `github.event.pull_request.user.login`.
- codeql-action upload-sarif **4.38.1**. Supply-chain result artifacts keep
  1 day. The sweeper also deletes `*.dockerbuild`.
- Debian image lint sets `run_secrets_scan: true`. Scans skip the
  `_commondevops` script checkout.
- containerdevops callers pin **6.0.1** (`c01b12a9…`).

## [5.1.2] - 2026-09-15

### Changed

- Write 5.1.1 alpine/debian Hub digests into published rescans, Hub/Packages
  pages, and `check-ci-docker.sh`. No GitHub Release (does not republish images).

## [5.1.1] - 2026-09-15

### Changed

- Nested [containerdevops](https://github.com/pirlruc/containerdevops) pin is
  **5.0.2** (`32384866e5669dbde8bdecde153a6ae6ead728ed`) for image callers and
  published rescans (`handoff_package` + `digest`).
- Scheduled rescans pin `ci-lint:5.1.0@sha256:fc7d91c3…` and
  `ci-supply-chain:5.1.0@sha256:1bbe1ff6…` (was `ci-lint:4.0.0` /
  `ci-supply-chain:3.0.0`). Hub / GHCR docs target **5.1.1**; 5.1.0 alpine/debian
  digests are recorded as the previous immutable tags until 5.1.2 writeback.
- `scripts/check-ci-docker.sh` default image is the 5.1.0 Alpine digest.

## [5.1.0] - 2026-09-14

### Breaking

- Image callers pin [containerdevops 5.0.1](https://github.com/pirlruc/containerdevops)
  (`2f33d910dbaf5bc0a9b5d6cabc56037a43077ebd`). Build jobs need
  `packages: write` and compose scan/publish refs from `handoff_package` +
  `digest` (`image_ref` is secret-masked when the Hub username equals the
  owner). Image tarballs are no longer the default handoff. Do not pin 5.0.0
  (`f5a3a632…`).

### Added

- Root CHANGELOG (REL-CHG-001). SC-SIGN-001 / SC-PROV-001 recorded for unsigned
  private publish.
- PR-only GHCR `ci-run-*` cleanup on `ci-lint` / `ci-supply-chain` image
  workflows. Scheduled `artifact-sweep.yml` for leftover `container-image*`
  artifacts.
- `common-scaffold-verify.yml` collect-then-fail aggregate gate.

### Fixed

- Local `run_zizmor` loads `.github/config/zizmor.yml` when present (parity
  with Actions).
- Alpine image lint runs secrets scan.
- `common-supply-chain.yml` reads `vuln_fail_on_severity` from the vendored
  thresholds instead of hardcoding HIGH.
- Debian Dockerfiles purge `-dev` packages only when `dpkg-query` shows them
  installed (no `|| true`).
- Token-free `pins` job runs on Dependabot PRs.

### Changed

- Host and image zizmor pins are exact `1.29.0` (was `>=1.0`).
- Hub / GHCR docs for `ci-lint` and `ci-supply-chain` target **5.1.0**.

## [5.0.0] - 2026-09-14

See GitHub Release notes for 5.0.0 (guardrails 1.6.0, fail-closed gates).
