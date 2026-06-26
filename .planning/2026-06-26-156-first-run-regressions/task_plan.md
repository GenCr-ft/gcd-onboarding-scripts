---
docId: GOV-PLAN-156
title: "[CODE] port(tests): WI-156 — port test_first_run_regressions.sh to main"
github-issue: GenCr-ft/gcd-onboarding-scripts#156
issue-id: GenCr-ft/gcd-onboarding-scripts#156
status: in-progress
created: '2026-06-26'
scope: first-run-regressions
---

# [CODE] WI-156 — Port test_first_run_regressions.sh to main

## Summary
Port `tests/test_first_run_regressions.sh` from `fix/issue-113-onboarding-first-run`
to main, applying 3 adaptations required by fixture/API drift.

## TDD Cycles

### Cycle 1 — Port file + fix fixture cp paths
- RED: add file verbatim from old branch (cp source files renamed → cp fails)
- GREEN: update `ensure_runtime_mock_ssot` cp paths: ENV_VARIABLES_STANDARD.md →
  ENG-STAN-002.environment-variable-standard.md, VSCODE_RECOMMENDATIONS.md →
  ENG-STAN-003.vs-code-extension-recommendations.md (both source and destination)

### Cycle 2 — detect_os → detect_os_arch rename
- GREEN: update `test_detect_os_is_available_to_main` to assert `declare -f detect_os_arch`
  (gft-onboarding.sh renamed function; old assertion fails after Cycle 1 GREEN)

### Cycle 3 — Replace workspace-root test with configure-env test
- GREEN: replace `test_workspace_root_expands_home_syntax` (tests removed function
  `gft_workspace_root`) with `test_configure_env_expands_projects_home`

### Cycle 4 — Extend to test both tilde and $HOME expansion paths
- GREEN: rewrite `test_configure_env_expands_projects_home` to cover both expansion
  branches (~/tilde_studio AND $HOME/dollar_studio) via in-place SSoT fixture mutation
  on $GFT_SSOT_PATH with save/restore, avoiding readonly variable constraint
