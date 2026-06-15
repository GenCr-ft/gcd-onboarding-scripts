---
docId: GOV-PLAN-OB-125
title: "[CODE] #125 — PS1 filename consistency test"
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#125
---

# [CODE] #125 — PS1 filename consistency test

## Scope

`tests/test_onboarding_logic.sh` only. New test function + registration.

## Changes

| File | Change |
|------|--------|
| `tests/test_onboarding_logic.sh` | Add `test_win_bootstrap_filename_consistency()` and register in `main()` |

## Plan

New test function:
1. Grep `onboarding-win.ps1` for `$BashOnboardingScriptName` assignment line.
2. Extract the filename value from the assignment.
3. Assert extracted value equals `"gft-onboarding.sh"`.
4. Assert `${PROJECT_ROOT}/gft-onboarding.sh` exists on disk.
5. Register as last test in `main()`.
