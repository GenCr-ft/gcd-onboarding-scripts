---
docId: GOV-PLAN-OB-124
title: "[SPEC] #124 — Remove phantom checksum prose"
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#124
---

# [SPEC] #124 — Remove phantom checksum prose

## Scope

README.md only. Single-phrase removal.

## Changes

| File | Change |
|------|--------|
| `README.md` | Remove "to verify checksums and " from Windows section intro line |

## Plan

1. Find: "Run via PowerShell as Administrator to verify checksums and bootstrap WSL2:"
2. Replace with: "Run via PowerShell as Administrator to bootstrap WSL2:"
3. Verify no other `.sha256` references remain in the file.
