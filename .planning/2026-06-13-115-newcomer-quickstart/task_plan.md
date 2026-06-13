---
docId: GOV-PLAN-115
issue-id: GenCr-ft/gcd-onboarding-scripts#115
title: "[CODE] Improve newcomer quickstart onboarding flow"
created: 2026-06-13
status: complete
---

# Task Plan

## Goal
Make the onboarding script usable by a new GenCr@ft contributor who only knows
the organization link and a bounded workspace name.

## Phases

### Phase 1: Refinement
- [x] Refine parent issue acceptance criteria.
- [x] Create and close design sub-issue `#116`.
- [x] Post implementation plan on issue `#115`.
- Status: complete

### Phase 2: Red
- [x] Add regression coverage for `--quickstart --workspace`.
- [x] Cover valid workspace ids, invalid workspace errors, `--workspace=<id>`, `--role`, and `--help`.
- Status: complete

### Phase 3: Green
- [x] Add CLI parsing helpers.
- [x] Map bounded workspaces to roles and repository bundles.
- [x] Route script execution through the parser before the generic abort trap.
- [x] Forward Windows quickstart arguments to the bash orchestrator.
- Status: complete

### Phase 4: Documentation
- [x] Document the five-command-or-less quickstart path.
- [x] Document valid workspace ids.
- [x] Update changelog.
- Status: complete

### Phase 5: Verification
- [x] Run `bash tests/test_onboarding_logic.sh`.
- [x] Run `bash ./test.sh`.
- Status: complete
