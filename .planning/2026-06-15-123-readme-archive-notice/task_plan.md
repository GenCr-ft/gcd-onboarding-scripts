---
docId: GOV-PLAN-OB-123
title: "[SPEC] #123 — README archive-required notice"
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#123
---

# [SPEC] #123 — README archive-required notice

## Scope

README.md only. No code changes.

## Changes

| File | Change |
|------|--------|
| `README.md` | Add archive-required note in Start Here block and macOS & Linux section |

## Plan

1. In "Start Here" quickstart block: add one sentence after the `bash gft-onboarding.sh` command — "The full archive including `includes/` is required; downloading the script alone is not supported."
2. In "macOS & Linux" section: same note after the `curl` tarball command.
3. Ensure no single-file download instructions remain anywhere in the file.
