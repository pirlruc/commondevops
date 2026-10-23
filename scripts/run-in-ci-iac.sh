#!/bin/sh
# Run a command in the ci-iac image with the workspace mounted at /workspace.
# Usage: run-in-ci-iac.sh <image> <command> [args...]
set -eu

if [ "$#" -lt 2 ]; then
	echo "usage: run-in-ci-iac.sh <image> <command> [args...]" >&2
	exit 2
fi

image="$1"
shift

docker run --rm \
	--read-only \
	--cap-drop ALL \
	--security-opt no-new-privileges \
	--tmpfs /tmp:rw,nosuid,nodev,mode=1777 \
	-v "${PWD}:/workspace" \
	-w /workspace \
	-e HOME=/tmp \
	--user "$(id -u):$(id -g)" \
	"${image}" \
	"$@"
