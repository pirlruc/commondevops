#!/bin/sh
# TOFU-LINT-001/002/003 and TOFU-BUILD-001. Does not plan or apply.
# A directory with .terraform.lock.hcl is a root module.
set -eu

ROOT="${1:-.}"
cd "${ROOT}"

list="$(find . -name '*.tf' -not -path '*/.terraform/*' -not -path '*/.git/*' || true)"
if [ -z "${list}" ]; then
	echo "no .tf files; tofu verify skipped"
	exit 0
fi

tofu fmt -check -recursive

if [ ! -f .tflint.hcl ]; then
	echo "TOFU-LINT-003: missing .tflint.hcl" >&2
	exit 1
fi

locks="$(find . -name '.terraform.lock.hcl' -not -path '*/.terraform/*' -not -path '*/.git/*' || true)"
if [ -z "${locks}" ]; then
	echo "TOFU-BUILD-001: .tf files exist and no .terraform.lock.hcl is committed" >&2
	exit 1
fi

tflint --init
tflint --recursive

while IFS= read -r lock; do
	[ -n "${lock}" ] || continue
	dir="$(dirname "${lock}")"
	echo "tofu init/validate ${dir}"
	(
		cd "${dir}"
		tofu init -backend=false -input=false
		tofu validate
	)
done <<EOF
${locks}
EOF
