#!/usr/bin/env bash
# Install pinned common CI tooling into $HOME/.local/bin when not present.
# Optional: INSTALL_ONLY=actionlint,hadolint,shellcheck  (comma-separated).
#
# DHI-sourced tools (syft, grype, trivy, shellcheck in ci-supply-chain / ci-lint)
# are expected from ghcr.io/pirlruc/ci-supply-chain and ghcr.io/pirlruc/ci-lint —
# this script covers runner-host installs for workflows that do not yet run
# inside those images.
#
# Tool versions are NOT Dependabot-managed. Bump manually with matching *_SHA256.
set -euo pipefail
DEST="${HOME}/.local/bin"
mkdir -p "${DEST}"
export PATH="${DEST}:${PATH}"

# https://github.com/hadolint/hadolint/releases
HADOLINT_VERSION="${HADOLINT_VERSION:-2.12.0}"
HADOLINT_SHA256="${HADOLINT_SHA256:-56de6d5e5ec427e17b74fa48d51271c7fc0d61244bf5c90e828aab8362d55010}"
# https://github.com/rhysd/actionlint/releases
ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-1.7.12}"
ACTIONLINT_SHA256="${ACTIONLINT_SHA256:-8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8}"
# https://github.com/koalaman/shellcheck/releases
SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-0.10.0}"
SHELLCHECK_SHA256="${SHELLCHECK_SHA256:-6c881ab0698e4e6ea235245f22832860544f17ba386442fe7e9d629f8cbedf87}"
# https://github.com/gitleaks/gitleaks/releases
GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.21.2}"
GITLEAKS_SHA256="${GITLEAKS_SHA256:-5bc41815076e6ed6ef8fbecc9d9b75bcae31f39029ceb55da08086315316e3ba}"
# https://github.com/aquasecurity/trivy/releases
TRIVY_VERSION="${TRIVY_VERSION:-0.73.0}"
TRIVY_SHA256="${TRIVY_SHA256:-2edd39da482bb4e9831962487b68f68e3928ec3137794757f54d00383d79547b}"
# https://github.com/anchore/syft/releases
SYFT_VERSION="${SYFT_VERSION:-1.50.0}"
SYFT_SHA256="${SYFT_SHA256:-bf7b29ff57f06da30918266a0e1c2885a8f99784798d1bdb1628886aa015d788}"
# https://github.com/anchore/grype/releases
GRYPE_VERSION="${GRYPE_VERSION:-0.116.1}"
GRYPE_SHA256="${GRYPE_SHA256:-0122df7b655981abe547ad3d2190d65551dac6a2bfc80b4dc2a989b5d0587458}"
# https://github.com/anchore/grant/releases
GRANT_VERSION="${GRANT_VERSION:-0.6.8}"
GRANT_SHA256="${GRANT_SHA256:-6500f8bbf0f20fb993de8084686e199f0ba1eb494769ff75454286d5ef63f919}"

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(sha256sum "${file}" | awk '{print $1}')"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "error: SHA256 mismatch for ${file}" >&2
    echo "  expected: ${expected}" >&2
    echo "  actual:   ${actual}" >&2
    return 1
  fi
}
export -f verify_sha256

should_install() {
  local name="$1"
  local only="${INSTALL_ONLY:-}"
  if [[ -z "${only}" ]]; then
    return 0
  fi
  [[ ",${only}," == *",${name},"* ]]
}

install_if_missing() {
  local name="$1"
  shift
  if ! should_install "${name}"; then
    return 0
  fi
  if command -v "${name}" >/dev/null 2>&1; then
    echo "${name}: already on PATH ($(command -v "${name}"))"
    return 0
  fi
  echo "Installing ${name}…"
  "$@"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "error: ${name} not on PATH after install (PATH=${PATH})" >&2
    return 1
  fi
}

install_if_missing hadolint bash -c "
  curl -sSfL -o '${DEST}/hadolint' \
    'https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64'
  verify_sha256 '${DEST}/hadolint' '${HADOLINT_SHA256}'
  chmod +x '${DEST}/hadolint'
"

install_if_missing actionlint bash -c "
  curl -sSfL -o /tmp/actionlint.tgz \
    'https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/actionlint.tgz '${ACTIONLINT_SHA256}'
  tar -xzf /tmp/actionlint.tgz -C '${DEST}' actionlint
  chmod +x '${DEST}/actionlint'
  rm -f /tmp/actionlint.tgz
"

install_if_missing shellcheck bash -c "
  curl -sSfL -o /tmp/shellcheck.txz \
    'https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz'
  verify_sha256 /tmp/shellcheck.txz '${SHELLCHECK_SHA256}'
  tar -xJf /tmp/shellcheck.txz -C /tmp
  cp \"/tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck\" '${DEST}/shellcheck'
  chmod +x '${DEST}/shellcheck'
  rm -rf /tmp/shellcheck.txz \"/tmp/shellcheck-v${SHELLCHECK_VERSION}\"
"

install_if_missing gitleaks bash -c "
  curl -sSfL -o /tmp/gitleaks.tgz \
    'https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz'
  verify_sha256 /tmp/gitleaks.tgz '${GITLEAKS_SHA256}'
  tar -xzf /tmp/gitleaks.tgz -C '${DEST}' gitleaks
  rm -f /tmp/gitleaks.tgz
"

install_if_missing trivy bash -c "
  curl -sSfL -o /tmp/trivy.tgz \
    'https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz'
  verify_sha256 /tmp/trivy.tgz '${TRIVY_SHA256}'
  tar -xzf /tmp/trivy.tgz -C '${DEST}' trivy
  rm -f /tmp/trivy.tgz
"

install_if_missing syft bash -c "
  curl -sSfL -o /tmp/syft.tgz \
    'https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/syft.tgz '${SYFT_SHA256}'
  tar -xzf /tmp/syft.tgz -C '${DEST}' syft
  rm -f /tmp/syft.tgz
"

install_if_missing grype bash -c "
  curl -sSfL -o /tmp/grype.tgz \
    'https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/grype.tgz '${GRYPE_SHA256}'
  tar -xzf /tmp/grype.tgz -C '${DEST}' grype
  rm -f /tmp/grype.tgz
"

install_if_missing grant bash -c "
  curl -sSfL -o /tmp/grant.tgz \
    'https://github.com/anchore/grant/releases/download/v${GRANT_VERSION}/grant_${GRANT_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/grant.tgz '${GRANT_SHA256}'
  tar -xzf /tmp/grant.tgz -C '${DEST}' grant
  rm -f /tmp/grant.tgz
"

echo "Tool install complete. PATH=${PATH}"
echo "Note: prefer ghcr.io/pirlruc/ci-lint and ghcr.io/pirlruc/ci-supply-chain for DHI-pinned toolchain images when available."
