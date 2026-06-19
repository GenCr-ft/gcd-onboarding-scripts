#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FIXTURE="${PROJECT_ROOT}/tests/fixtures/mock_ssot/tooling/ssot/.tool-versions-gft"
REMOTE_URL="${SSOT_PARITY_REMOTE_URL:-https://raw.githubusercontent.com/GenCr-ft/gcs-core-governance/main/tooling/ssot/.tool-versions-gft}"

if [[ -z "${CROSS_REPO_PAT:-}" ]]; then
  if [[ -n "${CI:-}" ]]; then
    echo "[ERROR] CROSS_REPO_PAT is empty in CI — secret not configured" >&2
    exit 1
  fi
  echo "[WARN] CROSS_REPO_PAT not set — skipping parity check" >&2
  exit 0
fi

response=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: token ${CROSS_REPO_PAT}" \
  "${REMOTE_URL}" || true)
http_code=$(printf '%s' "$response" | tail -n1)
production_content=$(printf '%s' "$response" | awk 'NR>1{print prev} {prev=$0}')

if [[ "$http_code" != "200" ]]; then
  echo "[ERROR] Fetch failed (HTTP ${http_code}): check CROSS_REPO_PAT and remote URL" >&2
  exit 1
fi

if [[ ! -f "$FIXTURE" ]]; then
  echo "[ERROR] Fixture missing: ${FIXTURE}" >&2
  exit 1
fi

normalize() { grep -v '^\s*#' | grep -v '^\s*$' | awk '{print $1, $2}' | LC_ALL=C sort; }

diff_output=$(diff \
  <(printf '%s\n' "$production_content" | normalize) \
  <(normalize < "$FIXTURE") 2>&1 || true)

if [[ -n "$diff_output" ]]; then
  echo "[FAIL] Fixture drift detected:" >&2
  printf '%s\n' "$diff_output" >&2
  exit 1
fi

echo "[PASS] Fixture matches production."
