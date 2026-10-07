#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "Commit the complete version before building its corresponding source." >&2
  exit 1
fi
build_context=$(mktemp -d)
trap 'rm -rf "$build_context"' EXIT
git archive HEAD | tar -x -C "$build_context"
docker build -t "${DOCUSEAL_IMAGE:-docuseal-dielca:$(git rev-parse --short HEAD)}" "$build_context"
