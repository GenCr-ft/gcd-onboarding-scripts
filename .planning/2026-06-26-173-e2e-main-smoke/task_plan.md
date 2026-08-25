---
docId: GOV-PLAN-OB-173
title: "[CODE] #173 — Create tests/test_e2e_main_smoke.sh"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#173
---

# [CODE] #173 — E2E main orchestration smoke tests

## Scope

Create `tests/test_e2e_main_smoke.sh` with two standalone E2E suites that exercise
`main()` from `gft-onboarding.sh` with all external I/O stubbed.

**E2E-1**: Verify main() exits 0, emits welcome + completion banners, and that
configure_environment_variables writes the .bashrc filesystem artifact.

**E2E-2**: Verify main() aborts (non-zero exit) when run_preflight() fails (uses
exit 1 in stub to force subshell abort — using return 1 is insufficient because
set -e propagation is suppressed through the full include sourcing chain).

## Branch

`feat/issue-173-e2e-main-smoke`

## Status

Both suites pass. 8/8 test files pass in full suite.
