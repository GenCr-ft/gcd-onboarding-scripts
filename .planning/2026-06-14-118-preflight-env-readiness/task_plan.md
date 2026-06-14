---
docId: GOV-PLAN-118
issue-id: GenCr-ft/gcd-onboarding-scripts#118
title: "[CODE] Workspace-aware preflight environment readiness check"
created: 2026-06-14
status: complete
---

# Task Plan

## Goal
Replace check_prerequisites with a workspace-aware run_preflight that
validates environment readiness (tools, connectivity, Git config, disk
space, org membership) before the main onboarding flow proceeds.

## Phases

### Phase 1: Scaffolding (Task 1/8)
- [x] Create includes/07_preflight.sh stub with mockable helpers.
- [x] Wire source line into gft-onboarding.sh.
- [x] Replace check_prerequisites call with run_preflight in main().
- [x] Confirm existing tests pass.

### Phase 2: Check implementation (Tasks 2–7)
- [ ] Implement _pf_build_checks and individual check functions.
- [ ] Implement run_preflight orchestration loop.
- [ ] Add test suite tests/test_preflight.sh.

### Phase 3: Integration (Task 8)
- [ ] Final integration tests and documentation.
