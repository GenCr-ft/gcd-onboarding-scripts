---
docId: GOV-PLAN-096
issue-id: GenCr-ft/gcd-onboarding-scripts#96
title: "[CODE] Correct workspace bundle documentation drift"
created: 2026-06-06
status: in_progress
---

# [CODE] Task Plan

## Goal
Correct the stale workspace bundle documentation so `deploy_workspace_files()` ships an `AGENTS.md` that matches the bounded-workspace model, the installed planning script path, and the current Phase 6 wording.

## Phases

### Phase 1: Discovery
- [x] Reproduce `tests/test_workspace_files.sh` failures
- [x] Isolate which shipped workspace files are stale
- Status: complete

### Phase 2: Implementation
- [x] Update `workspace/AGENTS.md` bounded-workspace references
- [x] Replace the stale planning init path
- [x] Remove the obsolete "pending GDD spec approvals" wording
- [ ] Update changelog
- Status: in_progress

### Phase 3: Verification
- [x] Run `bash tests/test_workspace_files.sh`
- [x] Run `bash test.sh`
- Status: complete

### Phase 4: Delivery
- [ ] Commit branch changes
- [ ] Open PR and update issue `#96`
- Status: pending
