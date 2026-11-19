#!/bin/sh
# Uso: changed.sh <saída> <regex>. Escreve <saída>=true no GITHUB_OUTPUT se algum
# arquivo do PR casa com a regex. Fora de PR (push na main), sempre true.
set -eu

name="$1"
pattern="$2"

if [ -z "${BASE_SHA:-}" ]; then
	echo "$name=true" >> "$GITHUB_OUTPUT"
	exit 0
fi

if git diff --name-only "$BASE_SHA" HEAD | grep -q -E "$pattern"; then
	echo "$name=true" >> "$GITHUB_OUTPUT"
else
	echo "$name=false" >> "$GITHUB_OUTPUT"
fi
