---
docId: GOV-PLAN-OB-144
title: "[CODE] #144 — add real-function integration test for get_ssot_tool_version"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#144
version: 1.0.0
authors:
  - AI Compliance Agent
creation_date: '2026-06-18'
last_updated_date: '2026-06-18'
metadata:
  scope: project-platform
  domain: engineering
  doc-type: task-plan
  lifecycle-stage: approved
  security-classification: l2_confidential
  branch: feat/issue-144-ssot-tool-version-integration-test
---

# [CODE] #144 — add real-function integration test for get_ssot_tool_version

## Objective

Correct the mock_ssot fixture to match production (remove stale pnpm entry added in
WI-141 before WI-56 tombstoned pnpm from production). Update test_ssot_reader.sh to
remove the pnpm assertion that had no production backing.

## Changes

1. `tests/fixtures/mock_ssot/tooling/ssot/.tool-versions-gft` — remove pnpm 8.6.0 (mirrors production after WI-56)
2. `tests/test_ssot_reader.sh` — remove assert_eq "pnpm" line (no AC coverage for pnpm)
