#!/usr/bin/env bash
# Tests for validate-environment.sh --orchestration flag

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)

PASS=0
FAIL=0
assert_eq() { if [[ "$1" == "$2" ]]; then echo "  [OK] $3"; ((PASS++)); else echo "  [FAIL] $3 — got '$1', expected '$2'"; ((FAIL++)); fi; }
assert_contains() { if echo "$1" | grep -q "$2"; then echo "  [OK] $3"; ((PASS++)); else echo "  [FAIL] $3 — '$2' not in output"; ((FAIL++)); fi; }

echo "=== test: --orchestration skips SSoT clone and role select ==="

FAKE_GEMOP=$(mktemp -d)
mkdir -p "${FAKE_GEMOP}/skills/skill-a" "${FAKE_GEMOP}/agents"
touch "${FAKE_GEMOP}/agents/gct-test-001.md"

FAKE_HOME=$(mktemp -d)
mkdir -p "${FAKE_HOME}/.claude/skills" "${FAKE_HOME}/.claude/agents"
ln -s "${FAKE_GEMOP}/skills/skill-a" "${FAKE_HOME}/.claude/skills/skill-a"
ln -s "${FAKE_GEMOP}/agents/gct-test-001.md" "${FAKE_HOME}/.claude/agents/gct-test-001.md"
cat > "${FAKE_HOME}/.claude/settings.local.json" <<'EOF'
{"hooks": {"PreToolUse": [], "PostToolUse": []}}
EOF

OUTPUT=$(HOME="$FAKE_HOME" GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP" \
    bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
RC=$?

assert_eq "$RC" "0" "exit code 0 when all checks pass"
assert_contains "$OUTPUT" "OK" "output contains [OK]"
assert_contains "$OUTPUT" "Checks Passed" "output contains summary"

echo ""
echo "=== test: --orchestration exits 1 when symlink missing ==="

FAKE_GEMOP2=$(mktemp -d)
mkdir -p "${FAKE_GEMOP2}/skills/skill-b" "${FAKE_GEMOP2}/agents"
touch "${FAKE_GEMOP2}/agents/gct-test-002.md"

FAKE_HOME2=$(mktemp -d)
mkdir -p "${FAKE_HOME2}/.claude/skills" "${FAKE_HOME2}/.claude/agents"
# Intentionally omit the symlinks

OUTPUT2=$(HOME="$FAKE_HOME2" GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP2" \
    bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
RC2=$?

assert_eq "$RC2" "1" "exit code 1 when symlinks missing"
assert_contains "$OUTPUT2" "FAIL" "output contains [FAIL]"

rm -rf "$FAKE_GEMOP" "$FAKE_HOME" "$FAKE_GEMOP2" "$FAKE_HOME2"

echo ""
echo "--- Results: $PASS passed, $FAIL failed ---"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
