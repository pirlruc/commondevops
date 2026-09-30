# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
