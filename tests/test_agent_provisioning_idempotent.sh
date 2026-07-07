#!/usr/bin/env bash
# ==============================================================================
# Test: provision_agent_files is idempotent — a pre-existing regular file at the
# target must be replaced with a symlink, not cause `ln -s` to abort. (WI-231)
# ==============================================================================
set -u
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true SCRIPT_DIR="$PROJECT_ROOT"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/01_helpers.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/05_agent_bootstrap.sh"

failed=0

gp=$(mktemp -d); mkdir -p "$gp/agents"; printf 'agent\n' > "$gp/agents/axiom.md"
home2=$(mktemp -d)
mkdir -p "$home2/.claude/agents"
printf 'stale copy\n' > "$home2/.claude/agents/axiom.md"   # pre-existing REGULAR file → old bug trigger

( HOME="$home2" GFT_SSOT_GEMOP_PATH="$gp" provision_agent_files >/dev/null 2>&1 ); rc=$?

[[ $rc -eq 0 ]] || { echo "FAIL: provision_agent_files aborted on a pre-existing regular file (rc=$rc)"; ((failed++)); }
if [[ -L "$home2/.claude/agents/axiom.md" ]]; then
  [[ "$(readlink "$home2/.claude/agents/axiom.md")" == "$gp/agents/axiom.md" ]] \
    || { echo "FAIL: target symlink does not point at the source agent file"; ((failed++)); }
else
  echo "FAIL: pre-existing regular file was not replaced by a symlink"; ((failed++))
fi

# Second run must also be a no-op success (idempotent)
( HOME="$home2" GFT_SSOT_GEMOP_PATH="$gp" provision_agent_files >/dev/null 2>&1 ) || { echo "FAIL: second provisioning run not idempotent"; ((failed++)); }

rm -rf "$gp" "$home2"

if [[ $failed -ne 0 ]]; then echo "🔴 test_agent_provisioning_idempotent: $failed failed."; exit 1; fi
echo "✓ test_agent_provisioning_idempotent: all checks passed."
