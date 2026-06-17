---
docId: GOV-PLAN-OB-139
title: "[CODE] #139 — post-merge review findings on #126 smoke test"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#139
version: 1.0.0
authors:
  - AI Compliance Agent
creation_date: '2026-06-16'
last_updated_date: '2026-06-16'
metadata:
  scope: project-platform
  domain: engineering
  doc-type: task-plan
  lifecycle-stage: approved
  security-classification: l2_confidential
  branch: fix/issue-139-smoke-test-cleanup
---

# [CODE] #139 — post-merge review findings on #126 smoke test
## Goal

Fix two defects in `test_main_orchestration_smoke` identified by post-merge
adversarial review of PR #138.

## Tasks

- [x] Replace `setup_ssot_repository()` stub: `mkdir -p /tmp` hardcoded path → `{ :; }`
- [x] Add `trap 'rm -rf "$smoke_home" "$smoke_ws" "$smoke_out"' RETURN` after `local exit_code=0`
- [x] Remove 3 explicit `rm` calls superseded by the trap
- [x] Verify full suite passes with `bash test.sh`