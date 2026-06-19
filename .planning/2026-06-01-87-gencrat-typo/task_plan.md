---
docId: GOV-PLAN-OB-87
title: "[CODE] #87 — correct GenCr@t typo in onboarding scripts and docs"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#87
version: 1.0.0
authors:
  - AI Compliance Agent
creation_date: '2026-06-01'
last_updated_date: '2026-06-19'
metadata:
  scope: project-platform
  domain: engineering
  doc-type: task-plan
  lifecycle-stage: approved
  security-classification: l2_confidential
  branch: fix/issue-87-gencrat-typo
---

# [CODE] #87 — correct GenCr@t typo in onboarding scripts and docs

## Goal

Replace all `GenCr@t` misspellings with `GenCr@ft` across text files in the repo.

## CRITICAL fixes (post adversarial review)

- Remove `local` keyword from top-level scope in `gft-onboarding.sh` line ~187
- Replace hardcoded `/home/lgan/hxgn/dev/claude/exp` path in `scratch/sync_onboarding_manuals.py`
  with `GFT_WORKSPACE_DIR` env var
