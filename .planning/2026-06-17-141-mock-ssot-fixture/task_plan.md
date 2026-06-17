---
docId: GOV-PLAN-OB-141
title: "[CODE] #141 — add .tool-versions-gft to mock_ssot fixture"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#141
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
  branch: fix/issue-141-mock-ssot-fixture
---

# [CODE] #141 — add .tool-versions-gft to mock_ssot fixture

## Objective

Add `tests/fixtures/mock_ssot/tooling/ssot/.tool-versions-gft` to make the mock SSoT
fixture tree complete. Update stale `lts-gallium` mock stub to `20.18.0`.

## Changes

1. `tests/fixtures/mock_ssot/tooling/ssot/.tool-versions-gft` — NEW FILE
2. `tests/test_onboarding_logic.sh` — update mock stub and assertion (lts-gallium → 20.18.0)
