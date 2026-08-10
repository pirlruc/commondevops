#!/usr/bin/env bash
# Install pinned common CI tooling into $HOME/.local/bin when not present.
# Optional: INSTALL_ONLY=actionlint,hadolint,shellcheck  (comma-separated).
#
# DHI-sourced tools (syft, grype, trivy, shellcheck in ci-base) are expected from
# ghcr.io/pirlruc/ci-base:latest — this script covers runner-host installs for
# workflows that do not yet run inside that image.
set -euo pipefail
DEST="${HOME}/.local/bin"
mkdir -p "${DEST}"
export PATH="${DEST}:${PATH}"

HADOLINT_VERSION="${HADOLINT_VERSION:-2.12.0}"
ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-1.7.7}"
SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-0.10.0}"
GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.21.2}"
TRIVY_VERSION="${TRIVY_VERSION:-0.73.0}"
SYFT_VERSION="${SYFT_VERSION:-1.50.0}"
GRYPE_VERSION="${GRYPE_VERSION:-0.116.1}"

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
  chmod +x '${DEST}/hadolint'
"

install_if_missing actionlint bash -c "
  curl -sSfL 'https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash' \
    | bash -s -- '${ACTIONLINT_VERSION}' '${DEST}'
"

install_if_missing shellcheck bash -c "
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq shellcheck
  else
    curl -sSfL -o /tmp/shellcheck.txz \
      'https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz'
    tar -xJf /tmp/shellcheck.txz -C /tmp
    cp \"/tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck\" '${DEST}/shellcheck'
    chmod +x '${DEST}/shellcheck'
    rm -rf /tmp/shellcheck.txz \"/tmp/shellcheck-v${SHELLCHECK_VERSION}\"
  fi
"

install_if_missing gitleaks bash -c "
  curl -sSfL -o /tmp/gitleaks.tgz \
    'https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz'
  tar -xzf /tmp/gitleaks.tgz -C '${DEST}' gitleaks
  rm -f /tmp/gitleaks.tgz
"

install_if_missing trivy bash -c "
  curl -sSfL -o /tmp/trivy.tgz \
    'https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz'
  tar -xzf /tmp/trivy.tgz -C '${DEST}' trivy
  rm -f /tmp/trivy.tgz
"

install_if_missing syft bash -c "
  curl -sSfL -o /tmp/syft.tgz \
    'https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz'
  tar -xzf /tmp/syft.tgz -C '${DEST}' syft
  rm -f /tmp/syft.tgz
"

install_if_missing grype bash -c "
  curl -sSfL -o /tmp/grype.tgz \
    'https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz'
  tar -xzf /tmp/grype.tgz -C '${DEST}' grype
  rm -f /tmp/grype.tgz
"

echo "Tool install complete. PATH=${PATH}"
echo "Note: prefer ghcr.io/pirlruc/ci-base for DHI-pinned syft/grype/trivy/shellcheck when available."
