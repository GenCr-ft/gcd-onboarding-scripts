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

1. `tests/fixtures/mock_ssot/tooling/ssot/.tool-versions-gft` — NEW FILE (fixture, mirrors production SSoT)
2. `tests/test_onboarding_logic.sh` — mock stub: lts-gallium → 20.18.0; add pnpm 8.6.0; assertion updated
3. `tests/test_ssot_reader.sh` — NEW FILE (6 assertions against real function, no mock override)
4. `includes/01_helpers.sh` — docstring example updated; `|| true` on grep pipeline (pipefail safety)
5. `spec/gft-developer-onboarding-specification.md` — update §1.4 example versions; fix §2.3.6 gft-cli SSoT claim
