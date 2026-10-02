#!/bin/sh
# Fail when a passed PAT has no expiry or remaining life over MAX_DAYS (CI-038).
# Warn when remaining life is under WARN_DAYS. Does not print token values.
set -eu

MAX_DAYS="${MAX_DAYS:-90}"
WARN_DAYS="${WARN_DAYS:-7}"
checked=0

check_one() {
  name="$1"
  token="$2"
  if [ -z "${token}" ]; then
    return 0
  fi
  checked=$((checked + 1))
  header="$(
    curl -sI -H "Authorization: Bearer ${token}" -H "User-Agent: commondevops-token-audit" \
      https://api.github.com/user | tr -d '\r' | awk 'BEGIN{IGNORECASE=1} /^github-authentication-token-expiration:/ {print $2, $3, $4}'
  )"
  if [ -z "${header}" ]; then
    echo "error: ${name} has no github-authentication-token-expiration header" >&2
    return 1
  fi
  expiry="$(date -u -d "${header}" +%s)"
  now="$(date -u +%s)"
  remaining_days="$(( (expiry - now) / 86400 ))"
  if [ "${remaining_days}" -gt "${MAX_DAYS}" ]; then
    echo "error: ${name} expires in ${remaining_days} days, over ${MAX_DAYS}" >&2
    return 1
  fi
  if [ "${remaining_days}" -lt "${WARN_DAYS}" ]; then
    echo "::warning::${name} expires in ${remaining_days} days"
  else
    echo "${name} expires in ${remaining_days} days"
  fi
}

fail=0
check_one scorecard_token "${SCORECARD_TOKEN:-}" || fail=1
check_one guardrails_token "${GUARDRAILS_TOKEN:-}" || fail=1
check_one checkout_token "${CHECKOUT_TOKEN:-}" || fail=1
if [ "${checked}" -eq 0 ]; then
  echo "error: no PAT was passed to the token audit" >&2
  exit 1
fi
exit "${fail}"
