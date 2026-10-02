# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
