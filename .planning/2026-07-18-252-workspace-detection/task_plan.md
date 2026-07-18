---
docId: GOV-PLAN-252
title: "[CODE] WI-252 — fix WORKSPACE detection for workspace-root invocation"
version: 1.0.0
authors:
  - Prism (GCT-VFX-VXL-001)
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#252
creation_date: '2026-07-18'
last_updated_date: '2026-07-18'
summary: "Replace fixed ../../ WORKSPACE resolution with landmark-based probe that works from both workspace root and gcd-onboarding-scripts/workspace/."
metadata:
  artifact-class: knowledge
  classification:
    category: to-govern
    type: plan
  lifecycle-phase: approved
  scope: project-aethel
  domain: developer-tooling
  doc-type: plan
  security-classification: l2_confidential
---

# [CODE] WI-252 — fix WORKSPACE detection for workspace-root invocation

Regression from #251: `dirname/../..` overshoots when script runs from workspace root.
Fix: `_detect_workspace()` probes for `gcl-srv-authentication` sibling at script dir
(root copy) and at `../../` (gcd-onboarding-scripts/workspace/).
