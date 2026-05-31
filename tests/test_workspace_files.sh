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

# ── Test 8: verify bounded workspace documentation in AGENTS.md and README.md ────
# We deployed files to $TMPDIR_DEPLOY. Let's inspect $TMPDIR_DEPLOY/README.md and $TMPDIR_DEPLOY/AGENTS.md.
# They should contain the five workspace IDs: aethel, evai-platform, workspace-ops, agent-factory, studio-gencraft
for ws in aethel evai-platform workspace-ops agent-factory studio-gencraft; do
  if grep -Fq "$ws" "${TMPDIR_DEPLOY}/README.md" && grep -Fq "$ws" "${TMPDIR_DEPLOY}/AGENTS.md"; then
    _pass "Bounded workspace '$ws' mentioned in README.md and AGENTS.md"
  else
    _fail "Bounded workspace '$ws' missing in README.md or AGENTS.md"
  fi
done

# They should reference the STATUS.md paths
for ws in aethel evai-platform workspace-ops agent-factory studio-gencraft; do
  if grep -Fq "gcs-project-management/workspaces/${ws}/STATUS.md" "${TMPDIR_DEPLOY}/README.md" || grep -Fq "gcs-project-management/workspaces/${ws}/STATUS.md" "${TMPDIR_DEPLOY}/AGENTS.md"; then
    _pass "STATUS.md path for '$ws' referenced in docs"
  else
    _fail "STATUS.md path for '$ws' missing in docs"
  fi
done

# They should reference Projects #17, #18, #19, #20, #22
for proj in "#17" "#18" "#19" "#20" "#22"; do
  if grep -Fq "$proj" "${TMPDIR_DEPLOY}/README.md" || grep -Fq "$proj" "${TMPDIR_DEPLOY}/AGENTS.md"; then
    _pass "Project $proj referenced in docs"
  else
    _fail "Project $proj missing in docs"
  fi
done

# They should describe Project #21 as governance/rollup only
if grep -Fq "#21" "${TMPDIR_DEPLOY}/README.md" || grep -Fq "#21" "${TMPDIR_DEPLOY}/AGENTS.md"; then
  if grep -i -Fq "rollup" "${TMPDIR_DEPLOY}/AGENTS.md" || grep -i -Fq "governance" "${TMPDIR_DEPLOY}/AGENTS.md"; then
    _pass "Project #21 correctly classified as governance/rollup"
  else
    _fail "Project #21 not classified as governance/rollup"
  fi
else
  _fail "Project #21 missing in docs"
fi

# Deployed docs must not contain contradictory Co-Authored-By instructions
if grep -Fq "Co-Authored-By:" "${TMPDIR_DEPLOY}/AGENTS.md"; then
  _fail "AGENTS.md contains forbidden Co-Authored-By trailer instruction"
else
  _pass "AGENTS.md does not contain forbidden Co-Authored-By instruction"
fi

# Deployed docs must not contain stale Phase 5 status or flat-only references
if grep -Fq "Phase 5" "${TMPDIR_DEPLOY}/README.md" || grep -Fq "Phase 5" "${TMPDIR_DEPLOY}/AGENTS.md"; then
  if grep -Fq "Phase 6" "${TMPDIR_DEPLOY}/README.md" && ! grep -Fq "Phase 5 (PCG Integration): IN PROGRESS" "${TMPDIR_DEPLOY}/README.md"; then
    _pass "Docs reflect Phase 6 status"
  else
    _fail "Docs still reference stale Phase 5 in progress"
  fi
else
  _pass "Docs do not mention Phase 5 in progress"
fi

# ── Test 9: verify test-all.sh workspace selectors ───────────────────────────
# Expose workspace selectors: --aethel, --evai-platform, --workspace-ops, --agent-factory, --studio-gencraft
for opt in --aethel --evai-platform --workspace-ops --agent-factory --studio-gencraft; do
  if bash "${TMPDIR_DEPLOY}/test-all.sh" --help | grep -Fq "$opt"; then
    _pass "test-all.sh --help documents selector $opt"
  else
    _fail "test-all.sh --help missing selector $opt"
  fi
done

# Proves existing test-all.sh flags still appear in --help and run/skip correctly
for opt in --server --pcg --client --ops; do
  if bash "${TMPDIR_DEPLOY}/test-all.sh" --help | grep -Fq "$opt"; then
    _pass "test-all.sh --help documents legacy selector $opt"
  else
    _fail "test-all.sh --help missing legacy selector $opt"
  fi
done

# ── Test 10: verify workspace.sh gracefully prints help without Poetry ───────
# We run workspace.sh --help. If we mock PATH or poetry command to not exist, it should exit 0 and print workspaces help.
if env PATH="/usr/bin:/bin" bash "${TMPDIR_DEPLOY}/workspace.sh" --help >/dev/null 2>&1; then
  _pass "workspace.sh --help exits 0 without Poetry installed"
else
  _fail "workspace.sh --help exits non-zero without Poetry installed"
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$TMPDIR_DEPLOY"
rm -rf "$TMPDIR_HOOKS"

echo ""
echo "  workspace_files: Passed: $PASS  Failed: $FAIL"
[[ "$FAIL" -eq 0 ]]
