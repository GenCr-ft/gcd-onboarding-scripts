---
docId: GOV-PLAN-OB-147
title: "[CODE] #147 — test_workspace_quickstart_contract path isolation and trap RETURN"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#147
version: 1.1.0
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
  branch: feat/issue-147-trap-return-quickstart-contract
---

# [CODE] #147 — test_workspace_quickstart_contract path isolation and trap RETURN

## Objective

Replace four hardcoded `/tmp/gft-*` paths in `test_workspace_quickstart_contract` with
`mktemp`-backed locals and add a `trap RETURN` guard for guaranteed cleanup.

## Changes

1. `tests/test_onboarding_logic.sh` — 4 mktemp locals + trap RETURN + remove explicit rm -f

## TDD Cycles

| Cycle | Status |
|-------|--------|
| WI-147.0 red  | complete — 7656156 |
| WI-147.1 green | complete — 1053aea |
| WI-147.2 blue  | complete — (this commit) |

## Adversarial Review Dispositions

- F1 HIGH: AC-1 wording corrected on issue — RETURN trap fires on `return`/fall-through, not set-e exits
- F2 HIGH: Blue commit added (this file update)
- F3 LOW: task_plan.md updated to complete
- F4 LOW: No trap-fire assertion — architectural restructuring out of scope for this WI
