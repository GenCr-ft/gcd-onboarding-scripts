---
docId: GOV-PLAN-198
title: "[CODE] feat(validate-env): WI-198 — validate-environment.sh testability"
github-issue: GenCr-ft/gcd-onboarding-scripts#198
issue-id: GenCr-ft/gcd-onboarding-scripts#198
status: in-progress
created: '2026-06-26'
scope: validate-environment-testability
---

# [CODE] WI-198 — validate-environment.sh testability

## Summary
Add 4 testability properties to `validate-environment.sh`:
env-var SSoT path injection (AC-1), non-interactive mode (AC-2),
BASH_SOURCE guard (AC-3), optional file soft-fail (AC-4).
Adversary review round 1 found HIGH: selected_role_name unbound in
non-interactive path — fixed in Cycle 3.

## TDD Cycles

### Cycle 1 — Remove readonly from GFT_SSOT_PATH (AC-1)
GREEN: `readonly GFT_SSOT_PATH=...` → `GFT_SSOT_PATH="${GFT_SSOT_PATH:-...}"`

### Cycle 2 — Add --optional flag to get_yaml_from_ssot (AC-4)
GREEN: add optional parameter; absent file + --optional → exit 0 + empty output

### Cycle 3 — GFT_NON_INTERACTIVE guard + adversary fix (AC-2)
GREEN: wrap git clone/select; declare selected_role_name="" before if-else;
       else branch: selected_role_name="${GFT_ROLE:-}"; validate_repos guard;
       file-scope globals (ROLE_MATRIX_YAML/TOOLING_SPECS_YAML)

### Cycle 4 — BASH_SOURCE guard (AC-3)
GREEN: main "$@" → if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
