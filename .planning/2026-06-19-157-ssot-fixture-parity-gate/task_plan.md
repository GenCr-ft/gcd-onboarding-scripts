---
docId: GOV-PLAN-OB-157
title: "[CODE] #157 — SSoT fixture parity CI gate"
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#157
version: 1.0.0
authors:
  - AI Compliance Agent
creation_date: '2026-06-19'
last_updated_date: '2026-06-19'
metadata:
  scope: project-platform
  cross-ref: GenCr-ft/gcs-core-governance#78
  design: GenCr-ft/gcs-core-governance#79
  impl: GenCr-ft/gcs-core-governance#80
---

# Implementation Plan: WI-157 SSoT fixture parity gate

## Deliverables

1. `tests/test_ssot_parity.sh` — new parity check script
2. `tests/fixtures/mock_ssot/tooling/ssot/.tool-versions-gft` — already present; verify content
3. `.github/workflows/ci.yml` — add `env: CROSS_REPO_PAT` to `unit-tests` step

## TDD Cycles

- Cycle 1a: offline skip guard
- Cycle 1b: CI secret-missing guard
- Cycle 2: missing fixture guard
- Cycle 3: parity pass (AC-1)
- Cycle 4: drift detection (AC-2)
- Cycle 5: CI gate (AC-3)
