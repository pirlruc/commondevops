# AI agent handoff — commondevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/commondevops/` |
| **Remote** | https://github.com/pirlruc/commondevops (PRIVATE) |
| **Role** | Reusable GitHub Actions for infra lint, secrets/SAST, supply-chain, Scorecard, release + `ci-base` image |
| **Type** | CI infrastructure |

## Scope

Owns `.github/workflows/common-*.yml`, `scripts/`, `docker/ci-base/`. Consumers
pin `pirlruc/commondevops@<sha>` and pass matching `scripts_ref` +
`checkout_token`.

Companion: [containerdevops](https://github.com/pirlruc/containerdevops) (OCI
image lifecycle), [pydevops](https://github.com/pirlruc/pydevops) (Python
quality).

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 0 — measurement baseline | **Done (local 2026-08-10):** cpp inline apt+venv ≈51s vs `ci-cpp` cold start ≈0.8s; container curl install ≈18.5s vs `ci-base` cold start ≈0.8s; uv already fast → **skip `ci-python`**. Build `ci-base`/`ci-cpp`/`ci-container`. |
| Phase 1 — repo foundation (files on disk) | Local tree authored; **no initial commit yet** |
| CMN-001 — reusable workflows | Authored in tree; not synced to GitHub issues |
| CMN-002 — ci-base image | Dockerfile + caller authored; image not published |
| CMN-003 — Dependabot SC-DEP | `.github/dependabot.yml` present |
| CMN-004 — ai-reviewer prompt | `docs/continuous-improvement.md` present |

## Pins

| Component | Ref |
|-----------|-----|
| guardrails submodule | tag `1.0.0` → commit `925b9f32659936382c67850ec125a182261710bf` (annotated tag object `d79a82d…`) |
| github-scaffold submodule | `0db5890f808e4a9b9d11eabfc9a95b2b90898fad` |
| containerdevops (ci-base caller) | `4185836ce6ea925e38d9b93c281b4ef8cf77c2d2` |
| actions/checkout | `3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1) |

## Commands

```bash
bash scripts/check-ci-local.sh
bash scripts/check-ci-docker.sh   # via COMMONDEVOPS_DOCKER_STEPS=…
bash scripts/pin-dhi-digests.sh docker/ci-base/Dockerfile
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/commondevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Private `checkout_token`:** Cross-repo callers must pass a PAT/fine-grained
  token with `contents:read` on this repo. Without it, nested sparse checkout
  fails with REST `Not Found`.
- **`scripts_ref`:** Must match the `uses:` pin. Never use `github.workflow_sha`
  (that is the *caller* workflow object). Empty `scripts_ref` falls back to
  `github.sha` of the *called* workflow only when the reusable lives in the
  same repo.
- **dhi.io login:** Building `docker/ci-base` needs Hub credentials
  (`DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`) for `docker login dhi.io`.
- **ci-base may be unpublished:** Workflows install tools via
  `install-common-tools.sh` until `ghcr.io/pirlruc/ci-base:latest` exists.
- **Empty git history:** Repo has no commits yet; submodule gitlinks need the
  first commit to record pins. Working tree clones are present under
  `docs/guardrails` and `.github/scaffold`.
- **Signing:** Keyless cosign / attestations need public repo or GHEC; keep
  `sign: false` while private and record a deviation if required.

## Suggested next work

1. Initial commit + push (approval-gated); enable Actions access for private
   reusable workflows (`access_level: user`).
2. Sync `docs/issues.yml` (dry-run first).
3. Publish `ci-base` via `ci-base-image.yml` once secrets are set.
4. Phase 0 measurement: capture baseline before migrating consumers.

## Recent history

- Phase 2 bootstrap: authored reusable workflows, scripts, ci-base Dockerfile,
  Dependabot, handoff, continuous-improvement prompt, issues manifest (2026-08-10).

*Last updated: 2026-08-10*
