#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GFT_DIR="${ROOT}/gcs-plt-tools/services/gft"

if ! command -v poetry >/dev/null 2>&1; then
  echo "poetry not found — install Poetry to use the workspace launcher." >&2
  exit 1
fi

cd "${GFT_DIR}"

if [[ "$#" -eq 0 ]]; then
  exec poetry run gft workspace menu
fi

exec poetry run gft workspace "$@"
