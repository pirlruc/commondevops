#!/bin/sh
# Fail when a vendored threshold key disagrees with the pinned guardrails
# submodule. Keys that exist only in the vendored file are commondevops
# extensions (license_allow_list patterns, vuln_fail_on_severity) and are
# not compared. POSIX sh (CI-022 / CI-035).
set -eu

SCRIPT_DIR="$(dirname "$0")"
SCRIPT_DIR="$(cd "${SCRIPT_DIR}" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

value_of() {
  file="$1"
  key="$2"
  line="$(grep -E "^${key}:" "${file}" || true)"
  if [ -z "${line}" ]; then
    echo "error: missing ${key} in ${file}" >&2
    return 1
  fi
  val="${line#*:}"
  val="${val%%#*}"
  # trim ends
  val="$(printf '%s' "${val}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  printf '%s' "${val}"
}

check_key() {
  vended="$1"
  upstream="$2"
  key="$3"
  left="$(value_of "${vended}" "${key}")"
  right="$(value_of "${upstream}" "${key}")"
  if [ "${left}" != "${right}" ]; then
    echo "error: ${key} drifted in ${vended}" >&2
    echo "  vendored: ${left}" >&2
    echo "  upstream: ${right}" >&2
    return 1
  fi
  echo "in sync: ${key}"
}

status=0
check_key \
  "${ROOT}/scripts/shell.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/shell/profile.thresholds.yml" \
  shellcheck_failure_threshold || status=1
check_key \
  "${ROOT}/scripts/shell.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/shell/profile.thresholds.yml" \
  shfmt_required || status=1
check_key \
  "${ROOT}/scripts/docker.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/docker/profile.thresholds.yml" \
  hadolint_failure_threshold || status=1
check_key \
  "${ROOT}/scripts/supply-chain.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/supply-chain/profile.thresholds.yml" \
  dependency_update_interval || status=1
check_key \
  "${ROOT}/scripts/supply-chain.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/supply-chain/profile.thresholds.yml" \
  dependency_update_open_pr_limit || status=1
check_key \
  "${ROOT}/scripts/supply-chain.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/supply-chain/profile.thresholds.yml" \
  dependency_update_blocked_semver_levels || status=1
check_key \
  "${ROOT}/scripts/supply-chain.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/supply-chain/profile.thresholds.yml" \
  dependency_update_cooldown_days || status=1
check_key \
  "${ROOT}/scripts/supply-chain.profile.thresholds.yml" \
  "${ROOT}/docs/guardrails/supply-chain/profile.thresholds.yml" \
  license_deny_list || status=1

if [ "${status}" -ne 0 ]; then
  exit 1
fi
echo "Vendored threshold keys match docs/guardrails."
