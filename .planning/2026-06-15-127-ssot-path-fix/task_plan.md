---
docId: GOV-PLAN-OB-127
title: "[CODE] #127 — fix SSoT path mismatch for ENV_VARIABLES_STANDARD.md"
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#127
---

# [CODE] #127 — fix SSoT path mismatch for ENV_VARIABLES_STANDARD.md

## Scope

`configure_environment_variables()` hard-exits when the env-vars spec is not found at
the old hardcoded path `tooling/ENV_VARIABLES_STANDARD.md`.

## Changes

| File | Change |
|------|--------|
| `includes/03_configuration.sh` | Replace hardcoded path check with `find`-based discovery; degrade gracefully if absent |
| `includes/get_standard_env_vars.py` | Accept optional second positional arg for the spec file path |

## Design

Use `find` with two `-name` patterns to match both the old fixture name
(`ENV_VARIABLES_STANDARD.md`) and the new gcs-core-governance name
(`*environment-variables-standard.md`). Pass the located path to the Python
helper as `$2` instead of having the helper re-derive it via `GFT_SSOT_PATH`.
