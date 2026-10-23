#!/bin/sh
# SOPS-SEC-001/002/003 and SOPS-LINT-001. Proves ciphertext. Does not decrypt.
set -eu

ROOT="${1:-.}"
cd "${ROOT}"

if [ -n "${SOPS_AGE_KEY:-}${AGE_SECRET_KEY:-}${SOPS_AGE_KEY_FILE:-}" ]; then
	echo "SOPS-SEC-003: an Age private key is present in the environment" >&2
	exit 1
fi

files="$(find . -type f -name '*.sops.*' ! -name '.sops.yaml' ! -name '.sops.yml' -not -path '*/.git/*' || true)"
config=""
if [ -f .sops.yaml ]; then
	config=".sops.yaml"
fi

if [ -z "${files}" ] && [ -z "${config}" ]; then
	echo "no sops files; encryption check skipped"
	exit 0
fi

if [ -n "${files}" ] && [ -z "${config}" ]; then
	echo "SOPS-SEC-002: sops files exist and .sops.yaml is missing" >&2
	exit 1
fi

if [ -n "${config}" ]; then
	if grep -q 'age1replace-with-the-operator-public-key' "${config}"; then
		echo "SOPS-SEC-002: .sops.yaml still names the placeholder recipient" >&2
		exit 1
	fi
	if ! grep -E -q 'age1[0-9a-z]{20,}' "${config}"; then
		echo "SOPS-SEC-002: .sops.yaml names no age recipient" >&2
		exit 1
	fi
fi

while IFS= read -r file; do
	[ -n "${file}" ] || continue
	if ! grep -E -q '^sops:' "${file}"; then
		echo "SOPS-SEC-001: ${file} has no sops metadata" >&2
		exit 1
	fi
done <<EOF
${files}
EOF

echo "sops ciphertext ok"
