---
docId: GOV-PLAN-OB-150
title: "[CODE] #150 — update parser refs to canonical SSoT filenames"
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#150
---

# [CODE] #150 — update parser refs to canonical SSoT filenames

## Scope

Update all hardcoded filename references in the onboarding parser scripts and
03_configuration.sh to use the new canonical docId-prefixed names provisioned
by gcs-core-governance#59 (WI-59).

## Changes

- `includes/get_standard_env_vars.py` — default path → `ENG-STAN-002.environment-variable-standard.md`
- `includes/get_vscode_extensions.py` — path → `ENG-STAN-003.vs-code-extension-recommendations.md`
- `includes/03_configuration.sh` — guard check (line 114) + find pattern (line 385) → ENG-STAN-003 / ENG-STAN-002
- `tests/fixtures/mock_ssot/tooling/ENV_VARIABLES_STANDARD.md` → renamed to `ENG-STAN-002.environment-variable-standard.md`
- `tests/fixtures/mock_ssot/tooling/VSCODE_RECOMMENDATIONS.md` → renamed to `ENG-STAN-003.vs-code-extension-recommendations.md`
