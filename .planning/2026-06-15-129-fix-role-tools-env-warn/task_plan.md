---
docId: GOV-PLAN-OB-129
title: "[CODE] #129 — fix role tools TypeError + env-var silent skip"
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#129
---

# [CODE] #129 — fix role tools TypeError + env-var silent skip

## Scope

Two bugs from the GFT_NON_INTERACTIVE smoke test.

## Changes

| File | Change |
|------|--------|
| `includes/get_role_tools.py` | Coerce dict tool entries to name string before set.add() |
| `includes/03_configuration.sh` | Change INFO → WARN when 0 env vars found from SSoT |

## Design

`get_role_tools.py`: when iterating tools, check `isinstance(tool, dict)` and
extract `tool.get("name", "")`. Handles the mixed YAML format where `common-base`
uses long-form (`- name: git`) while child roles use inline strings (`["opentofu"]`).

`03_configuration.sh`: the silent INFO log masks a real operational gap. Change to
`log_warn` so operators are alerted that the SSoT is missing structured env-var data.
Tracking content fix in gcs-core-governance#51.
