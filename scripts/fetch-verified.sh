#!/usr/bin/env bash
# CI-054. Retry a transport failure. A checksum mismatch is not retried.
# Source this file. It does not install tools.
set -euo pipefail

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

# A transport failure is retried. A checksum mismatch is not: the bytes are wrong.
fetch_verified() {
	local url="$1"
	local dest="$2"
	local expected="$3"
	local attempt
	for attempt in 1 2 3; do
		if curl --retry 2 --retry-delay 2 --retry-all-errors --fail --silent --show-error --location --output "${dest}" "${url}"; then
			if verify_sha256 "${dest}" "${expected}"; then
				return 0
			fi
			echo "error: checksum mismatch is not a transport failure; not retrying ${url}" >&2
			rm -f "${dest}"
			return 1
		fi
		echo "error: download failed (attempt ${attempt}) for ${url}" >&2
		rm -f "${dest}"
		sleep $((attempt * 2))
	done
	echo "error: download failed after 3 attempts: ${url}" >&2
	return 1
}

export -f verify_sha256
export -f fetch_verified
