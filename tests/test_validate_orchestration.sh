#!/usr/bin/env bash
# Tests for validate-environment.sh --orchestration flag

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)

PASS=0
FAIL=0
assert_eq() { if [[ "$1" == "$2" ]]; then echo "  [OK] $3"; PASS=$((PASS + 1)); else echo "  [FAIL] $3 — got '$1', expected '$2'"; FAIL=$((FAIL + 1)); fi; }
assert_contains() { if echo "$1" | grep -q "$2"; then echo "  [OK] $3"; PASS=$((PASS + 1)); else echo "  [FAIL] $3 — '$2' not in output"; FAIL=$((FAIL + 1)); fi; }

echo "=== test: --orchestration skips SSoT clone and role select ==="

FAKE_GEMOP=$(mktemp -d)
mkdir -p "${FAKE_GEMOP}/skills/skill-a" "${FAKE_GEMOP}/agents"
touch "${FAKE_GEMOP}/agents/gct-test-001.md"

FAKE_HOME=$(mktemp -d)
mkdir -p "${FAKE_HOME}/.claude/skills" "${FAKE_HOME}/.claude/agents"
ln -s "${FAKE_GEMOP}/skills/skill-a" "${FAKE_HOME}/.claude/skills/skill-a"
ln -s "${FAKE_GEMOP}/agents/gct-test-001.md" "${FAKE_HOME}/.claude/agents/gct-test-001.md"
cat > "${FAKE_HOME}/.claude/settings.json" <<'EOF'
{"hooks": {"PreToolUse": [], "PostToolUse": []}}
EOF

OUTPUT=$(HOME="$FAKE_HOME" GFT_WORKSPACE="$FAKE_HOME" GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP" \
    bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
RC=$?

assert_eq "$RC" "0" "exit code 0 when all checks pass"
assert_contains "$OUTPUT" "OK" "output contains [OK]"
assert_contains "$OUTPUT" "Checks Passed" "output contains summary"

echo ""
echo "=== test: --orchestration exits 1 when symlinks missing ==="

FAKE_GEMOP2=$(mktemp -d)
mkdir -p "${FAKE_GEMOP2}/skills/skill-b" "${FAKE_GEMOP2}/agents"
touch "${FAKE_GEMOP2}/agents/gct-test-002.md"

FAKE_HOME2=$(mktemp -d)
mkdir -p "${FAKE_HOME2}/.claude/skills" "${FAKE_HOME2}/.claude/agents"
# Symlinks intentionally omitted; no settings.json so both symlink and hook
# checks fail

OUTPUT2=$(HOME="$FAKE_HOME2" GFT_WORKSPACE="$FAKE_HOME2" GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP2" \
    bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
RC2=$?

assert_eq "$RC2" "1" "exit code 1 when symlinks missing"
assert_contains "$OUTPUT2" "FAIL" "output contains [FAIL]"

rm -rf "$FAKE_GEMOP" "$FAKE_HOME" "$FAKE_GEMOP2" "$FAKE_HOME2"

echo ""
echo "=== test: hook check reads workspace settings.json (not settings.local.json) ==="

FAKE_WS=$(mktemp -d)
FAKE_GEMOP_WS=$(mktemp -d)
mkdir -p "${FAKE_GEMOP_WS}/skills/skill-c" "${FAKE_GEMOP_WS}/agents"
touch "${FAKE_GEMOP_WS}/agents/gct-test-003.md"

mkdir -p "${FAKE_WS}/.claude/skills" "${FAKE_WS}/.claude/agents"
ln -s "${FAKE_GEMOP_WS}/skills/skill-c" "${FAKE_WS}/.claude/skills/skill-c"
ln -s "${FAKE_GEMOP_WS}/agents/gct-test-003.md" "${FAKE_WS}/.claude/agents/gct-test-003.md"
mkdir -p "${FAKE_WS}/.claude"
cat > "${FAKE_WS}/.claude/settings.json" <<'EOF'
{"hooks": {"PreToolUse": [], "PostToolUse": []}}
EOF
FAKE_HOME_EMPTY=$(mktemp -d)

OUTPUT_WS=$(HOME="$FAKE_HOME_EMPTY" GFT_WORKSPACE="$FAKE_WS" \
    GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP_WS" \
    bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
RC_WS=$?

assert_eq "$RC_WS" "0" "exit 0 when settings.json in GFT_WORKSPACE/.claude/"
assert_contains "$OUTPUT_WS" "Hooks block present" "hooks check passes for workspace settings"

echo ""
echo "=== test: hook check fails when workspace settings.json absent ==="

FAKE_WS2=$(mktemp -d)
FAKE_GEMOP_WS2=$(mktemp -d)
mkdir -p "${FAKE_GEMOP_WS2}/skills/skill-d" "${FAKE_GEMOP_WS2}/agents"
touch "${FAKE_GEMOP_WS2}/agents/gct-test-004.md"
mkdir -p "${FAKE_WS2}/.claude/skills" "${FAKE_WS2}/.claude/agents"
ln -s "${FAKE_GEMOP_WS2}/skills/skill-d" "${FAKE_WS2}/.claude/skills/skill-d"
ln -s "${FAKE_GEMOP_WS2}/agents/gct-test-004.md" "${FAKE_WS2}/.claude/agents/gct-test-004.md"
FAKE_HOME_WITH_LOCAL=$(mktemp -d)
mkdir -p "${FAKE_HOME_WITH_LOCAL}/.claude"
cat > "${FAKE_HOME_WITH_LOCAL}/.claude/settings.local.json" <<'EOF'
{"hooks": {"PreToolUse": [], "PostToolUse": []}}
EOF

OUTPUT_WS2=$(HOME="$FAKE_HOME_WITH_LOCAL" GFT_WORKSPACE="$FAKE_WS2" \
    GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP_WS2" \
    bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
RC_WS2=$?

assert_eq "$RC_WS2" "1" "exit 1 when workspace settings.json absent (even if settings.local.json exists)"
assert_contains "$OUTPUT_WS2" "FAIL" "hook check fails when workspace settings.json missing"

rm -rf "$FAKE_WS" "$FAKE_GEMOP_WS" "$FAKE_HOME_EMPTY" \
       "$FAKE_WS2" "$FAKE_GEMOP_WS2" "$FAKE_HOME_WITH_LOCAL"

echo ""
echo "--- Results: $PASS passed, $FAIL failed ---"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
