#!/usr/bin/env bash
# Tests for includes/06_workspace_files.sh — deploy_workspace_files()

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${TEST_DIR}/.." && pwd)"
export SCRIPT_DIR="$PROJECT_ROOT"
export TEST_ENV=true

PASS=0; FAIL=0

_pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
_fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

# Minimal log helpers so 06_workspace_files.sh can be sourced standalone
log_info()    { echo "[INFO]  $*"; }
log_success() { echo "[OK]    $*"; }
log_error()   { echo "[ERROR] $*" >&2; }

source "${PROJECT_ROOT}/includes/06_workspace_files.sh"

# ── Test 1: deploy to a fresh temp directory ──────────────────────────────────
TMPDIR_DEPLOY="$(mktemp -d)"
export GFT_PROJECTS_HOME="$TMPDIR_DEPLOY"

if deploy_workspace_files 2>/dev/null; then
  _pass "deploy_workspace_files exits 0 on fresh deploy"
else
  _fail "deploy_workspace_files exits 0 on fresh deploy"
fi

if [[ -f "${TMPDIR_DEPLOY}/test-all.sh" ]]; then
  _pass "test-all.sh deployed"
else
  _fail "test-all.sh deployed"
fi

if [[ -x "${TMPDIR_DEPLOY}/test-all.sh" ]]; then
  _pass "test-all.sh is executable"
else
  _fail "test-all.sh is executable"
fi

if [[ -f "${TMPDIR_DEPLOY}/AGENTS.md" ]]; then
  _pass "AGENTS.md deployed"
else
  _fail "AGENTS.md deployed"
fi

if grep -Fq "/home/lgan/.agents/skills/planning-with-files/scripts/init-session.sh" "${TMPDIR_DEPLOY}/AGENTS.md" 2>/dev/null; then
  _pass "AGENTS.md uses installed planning-with-files init path"
else
  _fail "AGENTS.md uses installed planning-with-files init path"
fi

if ! grep -Fq "/home/lgan/.claude/skills/planning-with-files/scripts/init-session.sh" "${TMPDIR_DEPLOY}/AGENTS.md" 2>/dev/null; then
  _pass "AGENTS.md does not reference stale planning-with-files init path"
else
  _fail "AGENTS.md does not reference stale planning-with-files init path"
fi

if [[ -f "${TMPDIR_DEPLOY}/workspace.sh" ]]; then
  _pass "workspace.sh deployed"
else
  _fail "workspace.sh deployed"
fi

if [[ -x "${TMPDIR_DEPLOY}/workspace.sh" ]]; then
  _pass "workspace.sh is executable"
else
  _fail "workspace.sh is executable"
fi

# ── Test 2: idempotent — second run exits 0 ───────────────────────────────────
if deploy_workspace_files 2>/dev/null; then
  _pass "deploy_workspace_files idempotent (exits 0 on re-run)"
else
  _fail "deploy_workspace_files idempotent (exits 0 on re-run)"
fi

# ── Test 3: stale file is updated ─────────────────────────────────────────────
echo "STALE_CONTENT_SENTINEL" > "${TMPDIR_DEPLOY}/test-all.sh"
if deploy_workspace_files 2>/dev/null; then
  _pass "deploy_workspace_files exits 0 when updating stale file"
else
  _fail "deploy_workspace_files exits 0 when updating stale file"
fi

if ! grep -q "STALE_CONTENT_SENTINEL" "${TMPDIR_DEPLOY}/test-all.sh"; then
  _pass "stale test-all.sh was overwritten with current content"
else
  _fail "stale test-all.sh was overwritten with current content"
fi

# ── Test 4: test-all.sh --help exits 0 ───────────────────────────────────────
if bash "${TMPDIR_DEPLOY}/test-all.sh" --help >/dev/null 2>&1; then
  _pass "deployed test-all.sh --help exits 0"
else
  _fail "deployed test-all.sh --help exits 0"
fi

# ── Test 5: test-all.sh WORKSPACE points to deploy dir ───────────────────────
# With no repos in the deploy dir, --server should skip every repo and still
# exit 0 (all skips, no fails).
if bash "${TMPDIR_DEPLOY}/test-all.sh" --server >/dev/null 2>&1; then
  _pass "test-all.sh --server exits 0 when all repos missing (all skip)"
else
  _fail "test-all.sh --server exits 0 when all repos missing (all skip)"
fi

# ── Test 6: missing workspace/ bundle returns non-zero ────────────────────────
ORIG_SCRIPT_DIR="$SCRIPT_DIR"
export SCRIPT_DIR="/nonexistent-path-12345"
if ! deploy_workspace_files 2>/dev/null; then
  _pass "deploy_workspace_files returns non-zero when bundle is missing"
else
  _fail "deploy_workspace_files returns non-zero when bundle is missing"
fi
export SCRIPT_DIR="$ORIG_SCRIPT_DIR"

# ── Test 7: deploy_planning_metadata_hook with chaining ───────────────────────
TMPDIR_HOOKS="$(mktemp -d)"
export GFT_PROJECTS_HOME="$TMPDIR_HOOKS"

# Create mock repos
mkdir -p "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks"
mkdir -p "${TMPDIR_HOOKS}/mock-repo-2/.git"

# Create mock linter
mkdir -p "${TMPDIR_HOOKS}/gcd-ops-scripts/src/gft_ops_scripts/linters"
MOCK_LINTER_PATH="${TMPDIR_HOOKS}/gcd-ops-scripts/src/gft_ops_scripts/linters/validate_planning_metadata.py"
echo "#!/usr/bin/env python3" > "$MOCK_LINTER_PATH"
echo "print('Mock linter executed')" >> "$MOCK_LINTER_PATH"
chmod +x "$MOCK_LINTER_PATH"

# Create an existing legacy hook in mock-repo-1 to test chaining
echo "#!/bin/sh" > "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks/pre-commit"
echo "echo 'Legacy hook executed'" >> "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks/pre-commit"
chmod +x "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks/pre-commit"

if deploy_planning_metadata_hook 2>/dev/null; then
  _pass "deploy_planning_metadata_hook exits 0 on success"
else
  _fail "deploy_planning_metadata_hook exits 0 on success"
fi

if [[ -f "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks/pre-commit" ]]; then
  _pass "pre-commit hook wrapper created for mock-repo-1"
else
  _fail "pre-commit hook wrapper created for mock-repo-1"
fi

if [[ -f "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks/pre-commit.legacy" ]]; then
  _pass "legacy hook successfully backed up to pre-commit.legacy"
else
  _fail "legacy hook successfully backed up to pre-commit.legacy"
fi

if grep -q "validate_planning_metadata.py" "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks/pre-commit"; then
  _pass "pre-commit wrapper invokes planning metadata linter"
else
  _fail "pre-commit wrapper invokes planning metadata linter"
fi

if grep -q "pre-commit.legacy" "${TMPDIR_HOOKS}/mock-repo-1/.git/hooks/pre-commit"; then
  _pass "pre-commit wrapper chains to pre-commit.legacy"
else
  _fail "pre-commit wrapper chains to pre-commit.legacy"
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$TMPDIR_DEPLOY"
rm -rf "$TMPDIR_HOOKS"

echo ""
echo "  workspace_files: Passed: $PASS  Failed: $FAIL"
[[ "$FAIL" -eq 0 ]]
