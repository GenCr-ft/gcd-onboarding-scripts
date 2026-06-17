---
docId: GOV-PLAN-OB-139
title: "[CODE] #139 — fix smoke stub CI race and temp-file leak"
status: approved
issue-id: GenCr-ft/gcd-onboarding-scripts#139
version: 1.0.0
authors:
  - AI Compliance Agent
creation_date: '2026-06-17'
last_updated_date: '2026-06-17'
metadata:
  scope: project-platform
  domain: engineering
  doc-type: task-plan
  lifecycle-stage: approved
  security-classification: l2_confidential
  branch: fix/issue-139-smoke-stub-trap-cleanup
---

# [CODE] #139 — fix smoke stub CI race and temp-file leak

## Objective

Fix two defects in `test_main_orchestration_smoke` in `tests/test_onboarding_logic.sh`:
1. Stub creates shared `/tmp/gft-ssot-onboarding` (CI race on parallel runners).
2. No `trap RETURN` — mktemp files leak if function exits unexpectedly under `set -e`.

## Changes

1. `tests/test_onboarding_logic.sh` — WI-139.0 (red): add regression assertion + pre-test cleanup for `/tmp/gft-ssot-onboarding`
2. `tests/test_onboarding_logic.sh` — WI-139.1 (green): stub `{ :; }`, add `trap RETURN`, remove explicit rms
3. WI-139.2 (blue): verify, no structural refactor needed

## TDD Cycle

### WI-139.0 — red commit

In `test_main_orchestration_smoke`:
- Before subshell: `rm -rf /tmp/gft-ssot-onboarding`
- After subshell result capture: assert `[[ ! -d /tmp/gft-ssot-onboarding ]]`
- **Expected state:** test FAILS (current stub creates the dir → assertion fires)
- Commit: `test: WI-139.0 — red: assert smoke stub leaves no /tmp/gft-ssot-onboarding`

### WI-139.1 — green commit

- L1063: `setup_ssot_repository() { :; }` (was `{ mkdir -p "/tmp/gft-ssot-onboarding"; }`)
- L1055+: `trap "rm -rf '$smoke_home' '$smoke_ws'; rm -f '$smoke_out'; trap - RETURN" RETURN`
- Remove explicit `rm` calls on L1082, L1086, L1089 (now covered by trap)
- **Expected state:** all tests PASS
- Commit: `fix: WI-139.1 — green: stub noop, trap RETURN cleanup`

### WI-139.2 — blue commit (if needed)

- No structural refactor required; skip or commit docs/comment improvement only.

## Test Command

```bash
bash /home/lgan/hxgn/dev/claude/exp/gcd-onboarding-scripts/test.sh
```

## Out of Scope

`/tmp/gft-workspace-parse.*` and `/tmp/gft-help.*` on lines 561–592 — separate follow-up issue.
