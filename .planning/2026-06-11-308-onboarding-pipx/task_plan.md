---
docId: GOV-PLAN-308
issue-id: GenCr-ft/gcd-onboarding-scripts#308
title: "[CODE] Enable idempotent pipx installation of gft-ops-scripts"
created: 2026-06-11
status: approved
---

# [CODE] Task Plan - Enable pipx installation of gft-ops-scripts

## Goal
Install and configure `gft-ops-scripts` idempotently using `pipx` in the onboarding script, ensuring linter binaries are globally available to hooks.

## Phases

### Phase 1: Implementation
- [ ] Implement direct installation of `gft-ops-scripts` via pipx
- [ ] Configure `gft-onboarding.sh` or its includes to perform pipx setup
- Status: in_progress

### Phase 2: Verification
- [ ] Run test suite for `gcd-onboarding-scripts`
- Status: pending
