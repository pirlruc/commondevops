#!/bin/sh
# Append an index and platform digest table to the GitHub Release for TAG.
# REL-PUB-005. Image refs are arguments. A missing ref fails the script.
set -eu

if [ -z "${TAG:-}" ] || [ -z "${REPO:-}" ]; then
  echo "TAG and REPO are required" >&2
  exit 1
fi
if [ "$#" -eq 0 ]; then
  echo "pass at least one image ref" >&2
  exit 1
fi

table="## Image digests

| Image | Index | Platform |
| --- | --- | --- |"

for ref in "$@"; do
  index=$(docker buildx imagetools inspect --format '{{json .Manifest.Digest}}' "${ref}" | tr -d '"')
  platforms=$(docker buildx imagetools inspect --format '{{range .Manifest.Manifests}}{{.Platform.OS}}/{{.Platform.Architecture}} {{.Digest}}{{println}}{{end}}' "${ref}")
  if [ -z "${platforms}" ]; then
    table="${table}
| \`${ref}\` | \`${index}\` | — |"
    continue
  fi
  oldifs=$IFS
  IFS='
'
  for row in ${platforms}; do
    [ -n "${row}" ] || continue
    plat=${row%% *}
    digest=${row#* }
    table="${table}
| \`${ref}\` | \`${index}\` | ${plat} \`${digest}\` |"
  done
  IFS=$oldifs
done

body=$(gh release view "${TAG}" --repo "${REPO}" --json body --jq .body)
printf '%s\n\n%s\n' "${body}" "${table}" > release-body.md
gh release edit "${TAG}" --repo "${REPO}" --notes-file release-body.md
echo "updated ${TAG}"
