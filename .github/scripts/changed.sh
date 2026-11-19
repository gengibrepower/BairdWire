#!/bin/sh
# Escreve run=true no GITHUB_OUTPUT se algum arquivo do PR casa com a regex $1.
# Fora de PR (push na main), sempre roda.
set -eu

if [ -z "${BASE_SHA:-}" ]; then
	echo "run=true" >> "$GITHUB_OUTPUT"
	exit 0
fi

changed=$(git diff --name-only "$BASE_SHA" HEAD)
echo "$changed"
if echo "$changed" | grep -q -E "$1"; then
	echo "run=true" >> "$GITHUB_OUTPUT"
else
	echo "run=false" >> "$GITHUB_OUTPUT"
fi
