# orchestration settings path fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix `check_orchestration_health()` in `validate-environment.sh` so the hook-registration check reads `$GFT_WORKSPACE/.claude/settings.json` (workspace-scoped, set by D-01) instead of `~/.claude/settings.local.json` (user-global, no longer used for studio hooks).

**Architecture:** Single-function targeted fix — change the `claude_settings` local variable assignment in the active `check_orchestration_health()` definition, remove the dead first definition, and update the existing orchestration test to exercise the corrected path. No new files needed.

**Tech Stack:** Bash (validate-environment.sh), bash test harness (tests/test_validate_orchestration.sh)

---

## Context

`validate-environment.sh` has **two** `check_orchestration_health()` function definitions:

- **Lines 148–213** — dead code (bash resolves to last definition; this one is never called)
- **Lines 218–284** — active definition, called by `main()` when `--orchestration` flag is set

The active definition (line 222) sets:
```bash
local claude_settings="${HOME}/.claude/settings.local.json"
```

After D-01 (gemop#84, gcs-plt-tools#262), studio hooks live in
`workspace/.claude/settings.json` (a symlink → gemop). The correct variable is:
```bash
local claude_settings="${GFT_WORKSPACE:-/home/lgan/hxgn/dev/claude/exp}/.claude/settings.json"
```

The existing test (`tests/test_validate_orchestration.sh`) creates `settings.local.json`
in the fake HOME, so it tests the old broken path. It must be updated to create
`settings.json` at the fake `GFT_WORKSPACE/.claude/` path.

**Tracking issue:** GenCr-ft/gcd-onboarding-scripts#65

---

## File Map

| Action  | File |
|---------|------|
| Modify  | `validate-environment.sh` |
| Modify  | `tests/test_validate_orchestration.sh` |

---

## Task 1 — Fix settings path in `check_orchestration_health()`

**Files:**
- Modify: `validate-environment.sh`
- Modify: `tests/test_validate_orchestration.sh`

- [ ] **Step 1: Write the failing tests**

  Add two new test scenarios to **the bottom** of `tests/test_validate_orchestration.sh`,
  before the final results block:

  ```bash
  echo ""
  echo "=== test: hook check reads workspace settings.json (not settings.local.json) ==="

  FAKE_WS=$(mktemp -d)
  FAKE_GEMOP_WS=$(mktemp -d)
  mkdir -p "${FAKE_GEMOP_WS}/skills/skill-c" "${FAKE_GEMOP_WS}/agents"
  touch "${FAKE_GEMOP_WS}/agents/gct-test-003.md"

  # Set up .claude in the workspace root (not HOME)
  mkdir -p "${FAKE_WS}/.claude/skills" "${FAKE_WS}/.claude/agents"
  ln -s "${FAKE_GEMOP_WS}/skills/skill-c" "${FAKE_WS}/.claude/skills/skill-c"
  ln -s "${FAKE_GEMOP_WS}/agents/gct-test-003.md" "${FAKE_WS}/.claude/agents/gct-test-003.md"
  # Write hooks to workspace settings.json (NOT settings.local.json)
  mkdir -p "${FAKE_WS}/.claude"
  cat > "${FAKE_WS}/.claude/settings.json" <<'EOF'
  {"hooks": {"PreToolUse": [], "PostToolUse": []}}
  EOF
  # HOME has no .claude at all — ensures old path cannot succeed by accident
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
  # workspace settings.json intentionally absent; settings.local.json present in HOME
  # to confirm the old path is NOT checked
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
  ```

  Also update the **two existing test scenarios** to use `GFT_WORKSPACE` / `settings.json` instead
  of `HOME` / `settings.local.json` for hook setup:

  - Test 1 ("skips SSoT clone and role select"): change from writing
    `${FAKE_HOME}/.claude/settings.local.json` to writing
    `${FAKE_HOME}/.claude/settings.json` AND pass `GFT_WORKSPACE="$FAKE_HOME"` to the invocation.
  - Test 2 ("exits 1 when symlinks missing"): remove the `settings.local.json` creation; add
    `GFT_WORKSPACE="$FAKE_HOME2"` to the invocation (the settings.json won't exist → hook check
    fails, exit 1, same expected outcome).

  Full updated test 1 invocation:
  ```bash
  OUTPUT=$(HOME="$FAKE_HOME" GFT_WORKSPACE="$FAKE_HOME" GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP" \
      bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
  ```

  Full updated test 2 invocation:
  ```bash
  OUTPUT2=$(HOME="$FAKE_HOME2" GFT_WORKSPACE="$FAKE_HOME2" GFT_SSOT_GEMOP_PATH="$FAKE_GEMOP2" \
      bash "${PROJECT_ROOT}/validate-environment.sh" --orchestration 2>&1)
  ```

  And change test 1's settings file creation:
  ```bash
  # Old (remove this):
  cat > "${FAKE_HOME}/.claude/settings.local.json" <<'EOF'
  {"hooks": {"PreToolUse": [], "PostToolUse": []}}
  EOF

  # New (replace with this):
  cat > "${FAKE_HOME}/.claude/settings.json" <<'EOF'
  {"hooks": {"PreToolUse": [], "PostToolUse": []}}
  EOF
  ```

- [ ] **Step 2: Run tests to confirm they fail**

  ```bash
  cd /home/lgan/hxgn/dev/claude/exp/gcd-onboarding-scripts
  bash tests/test_validate_orchestration.sh
  ```

  Expected: 2 new tests FAIL ("exit 0 when settings.json in GFT_WORKSPACE/.claude/" and
  "hooks check passes for workspace settings"). Original test 1 may also fail because
  `settings.local.json` was renamed to `settings.json` in the test fixture but the code
  still reads the old path.

- [ ] **Step 3: Fix `validate-environment.sh`**

  **3a. Remove dead first definition (lines 148–213).** Delete the entire block from line 148
  (`# Checks orchestration health: skill/agent symlinks and studio hooks registration`) through
  line 213 (closing `}` of the first `check_orchestration_health()`), including the blank line
  before the comment at line 147.

  **3b. Fix the settings path in the active definition (currently ~line 218, will shift up
  after 3a).**

  Find and replace this line in `check_orchestration_health()`:
  ```bash
  local claude_settings="${HOME}/.claude/settings.local.json"
  ```
  With:
  ```bash
  local claude_settings="${GFT_WORKSPACE:-/home/lgan/hxgn/dev/claude/exp}/.claude/settings.json"
  ```

  **3c. Update the log message** in the same function to match:

  Find:
  ```bash
          check_ok "Hooks block present in settings.local.json"
  ```
  Replace with:
  ```bash
          check_ok "Hooks block present in workspace settings.json"
  ```

  Find:
  ```bash
          check_fail "settings.local.json not found at ${claude_settings}"
  ```
  Replace with:
  ```bash
          check_fail "workspace settings.json not found at ${claude_settings}"
  ```

- [ ] **Step 4: Run tests to confirm they pass**

  ```bash
  bash tests/test_validate_orchestration.sh
  ```

  Expected: `6 passed, 0 failed` (2 original + 4 new assertions → 6 total).

- [ ] **Step 5: Confirm all other test suites still pass**

  ```bash
  bash tests/test_onboarding_logic.sh
  bash tests/test_package_manager_detection.sh
  bash tests/test_workspace_files.sh
  ```

  Expected: all pass (the change is additive/isolated to `check_orchestration_health`).

- [ ] **Step 6: Commit**

  ```bash
  cd /home/lgan/hxgn/dev/claude/exp/gcd-onboarding-scripts
  git checkout -b fix/65-orchestration-settings-path
  git add validate-environment.sh tests/test_validate_orchestration.sh
  git commit -m "fix(validate-environment): read workspace settings.json for hook check

  check_orchestration_health() was reading ~/.claude/settings.local.json
  for hook registration. After D-01 (gemop#84), studio hooks live in
  \$GFT_WORKSPACE/.claude/settings.json (workspace-scoped symlink).

  - Fix claude_settings path to use GFT_WORKSPACE env var with fallback
  - Remove dead first check_orchestration_health() definition (lines 148-213)
  - Update log messages to name the correct file
  - Update test fixtures to write settings.json at workspace path
  - Add 2 new test scenarios confirming workspace path is read and
    settings.local.json presence does NOT satisfy the check

  Closes #65"
  ```

---

## Task 2 — Open PR and close tracking issue

- [ ] **Step 1: Push branch and open PR**

  ```bash
  cd /home/lgan/hxgn/dev/claude/exp/gcd-onboarding-scripts
  git push -u origin fix/65-orchestration-settings-path
  gh pr create --repo GenCr-ft/gcd-onboarding-scripts \
    --title "fix(validate-environment): read workspace settings.json for hook check (#65)" \
    --body "$(cat <<'EOF'
  ## Summary

  - `check_orchestration_health()` was checking `~/.claude/settings.local.json` for hook
    registration. After D-01 (gemop#84 + gcs-plt-tools#262), studio hooks are workspace-scoped
    and live in `$GFT_WORKSPACE/.claude/settings.json`.
  - Removed dead first `check_orchestration_health()` definition (lines 148–213 in the old file).
  - Updated test fixtures to write to the correct path; added two new test scenarios that confirm
    the workspace path is used and that a `settings.local.json` in HOME does NOT satisfy the check.

  ## Test plan
  - [ ] `bash tests/test_validate_orchestration.sh` — 6 passed, 0 failed
  - [ ] `bash tests/test_onboarding_logic.sh` — all passed
  - [ ] `bash tests/test_package_manager_detection.sh` — all passed
  - [ ] `bash tests/test_workspace_files.sh` — all passed
  - [ ] End-to-end: `gft doctor` passes on a machine where D-01 sync-hooks has been run

  Closes #65
  EOF
  )"
  ```

- [ ] **Step 2: Two-stage review (per studio PR protocol)**

  Run `/superpowers:requesting-code-review` on the new PR.

- [ ] **Step 3: Merge (Studio Lead approval required)**

- [ ] **Step 4: Close tracking issue**

  ```bash
  gh issue close 65 --repo GenCr-ft/gcd-onboarding-scripts \
    --comment "Fixed in PR #<N> (fix/65-orchestration-settings-path). hook check now reads \$GFT_WORKSPACE/.claude/settings.json as required by D-01."
  ```

---

## Verification

After merging, end-to-end on a machine with D-01 sync-hooks applied:

```bash
# Should pass (workspace settings.json has hooks from gemop):
gft doctor
echo $?  # → 0

# Confirm old path is no longer consulted:
rm -f ~/.claude/settings.local.json
gft doctor
echo $?  # → 0 (still passes; hook check uses workspace path)
```
