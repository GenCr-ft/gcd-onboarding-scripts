---
docId: GOV-PLAN-186
title: "[CODE] fix(tests): restore CI green — parity test guard env isolation + auth-optional curl"
github-issue: GenCr-ft/gcd-onboarding-scripts#186
issue-id: GenCr-ft/gcd-onboarding-scripts#186
status: complete
created: '2026-06-25'
scope: parity-ci-fix
---

# [CODE] fix(tests): parity CI fix

Replace CI-hard-fail guard in test_ssot_parity.sh with auth-optional logic; add CI="" to parity guard test cycles 2a/2b.

## Cycles

- Cycle 1: Guard test env isolation — add CI="" to cycles 2a/2b of test_ssot_parity_guard.sh
- Cycle 2: Parity script auth-optional — replace lines 14-25 of test_ssot_parity.sh with conditional curl
