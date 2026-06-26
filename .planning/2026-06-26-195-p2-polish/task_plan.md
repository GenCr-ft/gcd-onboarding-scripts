---
docId: GOV-PLAN-OB-195
title: "[CODE] #195 — P2 polish: label renumbering, Set-ExecutionPolicy guard, WORKSPACE_DIR fix"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#195
---

# [CODE] #195 — P2 polish

## Scope

Three polish fixes across test infrastructure and scratch utility:

1. **Renumber `[TEST SUITE]` labels** (`tests/test_onboarding_logic.sh`) — fix duplicate label at line 460 (`[TEST SUITE 4]` → `[TEST SUITE 3b]`) and assign sequential numbers `[TEST SUITE 14]`–`[TEST SUITE 25]` to 12 bare entries in preflight and orchestration test functions.

2. **Add Set-ExecutionPolicy positive guard** (`tests/test_onboarding_logic.sh`) — regression guard in `test_auxiliary_scripts_windows_invocation_uses_clone()` that fails if PS5.1 bypass line is removed from docs.

3. **Fix hardcoded WORKSPACE_DIR** (`scratch/sync_onboarding_manuals.py`) — replace `/home/lgan/hxgn/dev/claude/exp` constant with `GFT_WORKSPACE_DIR` env-var lookup.

## Branch

`feat/issue-195-p2-polish`

## Status

All 3 cycles complete. All 7 test suites pass.
