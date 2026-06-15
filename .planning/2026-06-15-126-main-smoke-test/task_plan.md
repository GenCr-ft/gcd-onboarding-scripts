---
docId: GOV-PLAN-OB-126
title: "[CODE] #126 — main() orchestration smoke test"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#126
version: 1.0.0
authors:
  - AI Compliance Agent
creation_date: '2026-06-15'
last_updated_date: '2026-06-15'
metadata:
  scope: project-platform
  domain: engineering
  doc-type: task-plan
  lifecycle-stage: approved
  security-classification: l2_confidential
  branch: feat/issue-126-main-smoke-test
---

# [CODE] #126 — main() orchestration smoke test

## Goal

Add `test_main_orchestration_smoke()` to exercise `main()` end-to-end with an
isolated HOME and all network/side-effect steps stubbed out.

## Tasks

- [x] Insert `test_main_orchestration_smoke()` into `tests/test_onboarding_logic.sh`
- [x] Register it in the test runner `main()`
- [x] Verify full suite passes with `bash test.sh`
