---
docId: GOV-PLAN-172
title: "[CODE] Fix README and Windows bootstrap documentation gaps"
github-issue: GenCr-ft/gcd-onboarding-scripts#172
issue-id: GenCr-ft/gcd-onboarding-scripts#172
status: in-progress
created: '2026-06-19'
scope: readme-install-docs-windows-bootstrap
---

# [CODE] Fix README and Windows bootstrap documentation gaps

## Goal

Replace broken standalone-download install blocks in README with git clone.
Remove dangling `.sha256` references. Update `docs/auxiliary-scripts.md` for
consistency. Gate all changes with updated test assertions.

## Cycles

- Cycle 1: Flip `test_quickstart_documentation_contract` assertions + replace README install blocks
- Cycle 2: Add `test_auxiliary_scripts_windows_invocation_uses_clone` + prepend clone step to `docs/auxiliary-scripts.md`
