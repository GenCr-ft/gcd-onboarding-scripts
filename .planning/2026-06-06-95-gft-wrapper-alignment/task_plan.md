---
docId: GOV-PLAN-095
issue-id: GenCr-ft/gcd-onboarding-scripts#95
title: "[CODE] Align gft installer with workspace-managed wrapper contract"
created: 2026-06-06
status: in_progress
---

# Task Plan

## Goal
Align `gcd-onboarding-scripts` with the `gcs-plt-tools` workspace-managed `gft` wrapper contract so the studio onboarding flow no longer installs a competing global CLI model.

## Phases

### Phase 1: Discovery
- [x] Read repo instructions
- [x] Inspect current `install_gft_cli()` implementation
- [x] Inspect the post-clone `configure_gft_cli()` / validation flow
- Status: complete

### Phase 2: Contract
- [x] Record the delegated ownership model on issue `#95`
- [x] Decide where actual wrapper installation should happen in the orchestrator
- Status: complete

### Phase 3: Implementation
- [x] Replace isolated-venv install logic with delegation to `gcs-plt-tools/onboard.sh`
- [x] Ensure pre-clone and post-clone phases behave correctly
- [x] Update docs/changelog
- Status: complete

### Phase 4: Verification
- [x] Add regression coverage for deferred install and delegated install
- [x] Run onboarding logic suite
- [x] Run repo test suite and route unrelated failures
- Status: complete

### Phase 5: Delivery
- [ ] Push branch, open PR, and update issue `#95`
- Status: pending
