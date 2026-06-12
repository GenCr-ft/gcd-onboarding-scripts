---
docId: GOV-PLAN-111
issue-id: GenCr-ft/gcd-onboarding-scripts#111
title: "[CODE] Onboarding Scripts PEP 668 Remediation"
created: 2026-06-12
status: approved
---

# [CODE] Task Plan - Onboarding Scripts PEP 668 Remediation

## Goal
Make pipx installation resilient to PEP 668 and fix get_role_env_vars.py roles map parsing.

## Phases

### Phase 1: Implementation
- [x] Use package managers (apt, brew, dnf, pacman) first for pipx installation with --break-system-packages as fallback.
- [x] Add try-except around roles map parsing in get_role_env_vars.py.
- Status: complete

### Phase 2: Verification
- [x] Run test suite for `gcd-onboarding-scripts`
- Status: complete
