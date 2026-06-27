---
docId: GOV-PLAN-177
title: "[CODE] test(onboarding): WI-177 — SSoT path integration tests"
github-issue: GenCr-ft/gcd-onboarding-scripts#177
issue-id: GenCr-ft/gcd-onboarding-scripts#177
status: in-progress
created: '2026-06-27'
scope: ssot-path-integration-tests
---

# [CODE] WI-177 — SSoT path integration tests

## Summary
Add `tests/test_validate_environment_ssot_paths.sh` — an integration test suite
that exercises the real SSoT file-resolution logic in `validate-environment.sh`.
Tests require a live `gcs-core-governance` clone pointed to by `GFT_SSOT_PATH`;
when absent, they skip gracefully (CI-safe skip guard).

## TDD Cycles

All 4 cycles implemented in a single uninterrupted session (batch commit accepted
per policy — all cycles documented in this file).

### Cycle 1 — Skip guard (AC-4)
GREEN: top-of-file guard: if `GFT_SSOT_PATH` unset or directory absent, emit
`[SKIP]` token and `exit 0` before any sourcing of `validate-environment.sh`.

### Cycle 2 — ROLE_MATRIX_FILE resolution (AC-1)
GREEN: `test_role_matrix_file_resolves` — sources the script in a bash subshell
with `GFT_SSOT_PATH` injected before `source`, calls `get_yaml_from_ssot` on the
resolved path, asserts non-empty YAML returned.

### Cycle 3 — TOOLING_SPECS_FILE resolution when present (AC-2)
GREEN: `test_tooling_specs_file_resolves_when_present` — reads `TOOLING_SPECS_FILE`
constant from script, skips with `[SKIP]` token if file absent in clone (catalog
optional), otherwise asserts non-empty YAML.

### Cycle 4 — Defensive guard logs INFO for absent catalog (AC-3)
GREEN: `test_tooling_specs_absent_guard_logs_info` — creates a minimal mock SSoT
with only `ROLE_MATRIX_FILE` present, explicitly calls
`get_yaml_from_ssot "${GFT_SSOT_PATH}/${TOOLING_SPECS_FILE}" --optional`, runs
`validate_tools_for_role`, asserts exit 0 and INFO message (not ERROR/FAIL).
This is the regression guard for the `--optional` chain introduced in WI-198.

## Cycle → Commit Map

| Cycle | Commit |
|-------|--------|
| 1–4 (batch) | WI-177.1 — green: add SSoT path integration test with skip guard |
