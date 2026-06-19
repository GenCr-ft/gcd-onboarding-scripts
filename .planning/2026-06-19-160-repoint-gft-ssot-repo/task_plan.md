---
docId: GOV-PLAN-OB-160
title: "[CODE] #160 — repoint gft-onboarding-scripts SSoT from gcs-devops-standards to gcs-core-governance"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#160
branch: feat/issue-160-repoint-gft-ssot-repo
---

## Summary

Full SSoT migration: repoint all `gcs-devops-standards` references to `gcs-core-governance` across
executable code, tests, fixtures, and documentation.

Prior WIs (WI-127, WI-144, WI-150, WI-157) resolved most references. This WI resolves the remaining
gap: `validate-environment.sh` ROLE_MATRIX_FILE and TOOLING_SPECS_FILE path values retained stale
gcs-devops-standards path conventions (GOV-004 / tool-002) after the SSoT repo migration.

## Changes

- `validate-environment.sh:23` ROLE_MATRIX_FILE → `reference-libraries/devops-standards/foundations/governance/GOV-GUIDE-010.role-tooling--resource-matrix.md`
- `validate-environment.sh:24` TOOLING_SPECS_FILE → `reference-libraries/devops-standards/domains/tooling/standards/DEV-SPEC-014.tool-002-language-specific-tooling-standards.md`

## Design

[DESIGN] sub-issue: GenCr-ft/gcd-onboarding-scripts#167 (closed, status:approved)

## Implementation

[IMPL] sub-issue: GenCr-ft/gcd-onboarding-scripts#168 (status:approved)
Adversary review: 5 rounds, PASS (LIFECYCLE:ADVERSARY-REVIEW:IMPL:PASS)
