#!/usr/bin/env bash
# ==============================================================================
# Test: setup_ssot_repository handles absent / valid-clone / stale-non-git dirs
# (WI-227). Regression: a stale non-git $GFT_SSOT_PATH must be re-cloned, not
# `git pull`ed (which aborts with 'fatal: not a git repository').
# ==============================================================================
set -u
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true SCRIPT_DIR="$PROJECT_ROOT"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/01_helpers.sh"

failed=0
GIT_LOG=""   # records the git subcommands invoked

# Mock the two collaborators so no real network/git runs.
run_command_with_logging() { "$@"; }
git() { GIT_LOG+="git $* "$'\n'; return 0; }

export GFT_SSOT_REPO="https://example/repo.git"

# 1. Valid existing clone → git pull, NOT clone
tmp1="$(mktemp -d)"; mkdir -p "$tmp1/.git"
export GFT_SSOT_PATH="$tmp1"
GIT_LOG=""; setup_ssot_repository >/dev/null 2>&1
[[ "$GIT_LOG" == *"pull --ff-only"* ]] || { echo "FAIL: valid clone should pull"; ((failed++)); }
[[ "$GIT_LOG" != *"clone"* ]] || { echo "FAIL: valid clone should not re-clone"; ((failed++)); }
rm -rf "$tmp1"

# 2. Stale non-git dir → must remove and clone, NOT pull
tmp2="$(mktemp -d)"; echo junk > "$tmp2/leftover.txt"   # exists, no .git
export GFT_SSOT_PATH="$tmp2"
GIT_LOG=""; setup_ssot_repository >/dev/null 2>&1
[[ "$GIT_LOG" == *"clone"* ]] || { echo "FAIL: stale non-git dir should be re-cloned"; ((failed++)); }
[[ "$GIT_LOG" != *"pull"* ]] || { echo "FAIL: stale non-git dir must NOT be git-pulled"; ((failed++)); }
rm -rf "$tmp2" 2>/dev/null || true

# 3. Absent dir → clone
tmp3="$(mktemp -d)"; rmdir "$tmp3"   # ensure absent
export GFT_SSOT_PATH="$tmp3"
GIT_LOG=""; setup_ssot_repository >/dev/null 2>&1
[[ "$GIT_LOG" == *"clone"* ]] || { echo "FAIL: absent dir should be cloned"; ((failed++)); }
rm -rf "$tmp3" 2>/dev/null || true

if [[ $failed -ne 0 ]]; then echo "🔴 test_ssot_setup_idempotency: $failed failed."; exit 1; fi
echo "✓ test_ssot_setup_idempotency: all checks passed."
