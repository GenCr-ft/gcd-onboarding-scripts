---
docId: GOV-PLAN-OB-169
title: "[CODE] #169 — remove ssot-compliance job from ci.yml"
status: approved
issue-id: GenCr-ft/gcd-onboarding-scripts#169
version: 1.0.0
authors:
  - AI Compliance Agent
creation_date: '2026-06-19'
last_updated_date: '2026-06-19'
metadata:
  scope: gcd-onboarding-scripts
  domain: devops
  doc-type: implementation-plan
  lifecycle-stage: approved
  security-classification: l2_confidential
---

# [CODE] #169 — remove ssot-compliance job from ci.yml

## Change

Delete the `ssot-compliance:` job block from `.github/workflows/ci.yml`. No other changes.

## Verification

Post-merge CI run named "CI" (not `.github/workflows/ci.yml`) with unit-tests and shellcheck jobs visible.
