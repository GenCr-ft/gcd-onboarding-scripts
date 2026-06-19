---
docId: GOV-PLAN-OB-159
title: "[CODE] #159 — fix ci.yml continue-on-error schema error"
status: approved
issue-id: GenCr-ft/gcd-onboarding-scripts#159
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

# [CODE] fix(ci) — move continue-on-error to job level in ssot-compliance

## Change

Move `continue-on-error: true` from inside `with:` to job level in the `ssot-compliance` job of `.github/workflows/ci.yml`.

## Verification

Post-merge CI run name changes from `.github/workflows/ci.yml` to `CI`.
