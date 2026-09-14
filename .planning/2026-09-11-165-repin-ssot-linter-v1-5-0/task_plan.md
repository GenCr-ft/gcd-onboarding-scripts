---
docId: GOV-PLAN-165
title: '[CODE] WI-165.1 — re-pin the SSoT linter caller to @v1.5.0'
version: 1.0.0
issue-id: GenCr-ft/gcd-shared-actions#165
status: in_progress
authors: [loigallain]
creation_date: '2026-09-11'
last_updated_date: '2026-09-11'
language: en
summary: >-
  Re-pin this repository's reusable-ssot-linter caller from @v1.3.8 to @v1.5.0 so the
  job-level concurrency control released in that tag is actually executed here.
metadata:
  lifecycle-stage: draft
  scope: studio
  domain: engineering
  doc-type: backlog
  security-classification: l2_confidential
  keywords: [wi-165, ssot-linter, version-pin, concurrency, fleet-sweep]
---

# [CODE] WI-165.1 — re-pin the SSoT linter caller to @v1.5.0

## Why this repository is touched

A caller executes a reusable workflow **at the tag it pins**, not at the producer's `main`. So
`gcd-shared-actions@v1.5.0` — carrying the job-level `concurrency` control from
[GenCr-ft/gcd-shared-actions#175](https://github.com/GenCr-ft/gcd-shared-actions/issues/175) —
reached no consumer. Measured at `origin/main` of 34 real clones on 2026-09-11, linked worktrees
excluded by testing whether `.git` is a file:

| `uses:` pin | Sites |
|---|---|
| `@v1.3.8` | 27 |
| `@v1.3.1` / `@v1.3.2` / `@v1.3.5` | 1 each |
| `@v1.4.0` | 0 |
| `@v1.5.0` | **0** |

30 real `uses:` pin sites across 30 consumer repositories, of 34 real clones - one per repo. An earlier count of 32 was wrong: the enumerator matched the token inside two COMMENTS rather than `uses:` declarations, and in one repo that rewrote a comment citing a line number and falsified it. This repository holds one site.

## Scope

- The `uses:` pin in `.github/workflows/ssot-compliance.yml`, `@v1.3.x` -> `@v1.5.0`.
- **NOT in scope:** `governance-version` / `tooling-version`. They already carry `v1.6.1` /
  `v4.4.1` — the canonical pair recorded `rc: 0` in `policy/compatibility-matrix.yml`. `v1.5.0`
  adds a pin-compatibility preflight that refuses any pair not recorded green, so leaving the pair
  explicit and byte-identical is what makes the bump safe. Deleting the `with:` block to inherit
  the default is tracked separately as
  [GenCr-ft/gcs-project-management#579](https://github.com/GenCr-ft/gcs-project-management/issues/579).
- **NOT in scope:** `.github` and `.github-private` (`v1.4.0` / `v4.1.2`, and both pin the linter
  below `v1.3.4` where `governance-version` resolves the *archived* `gcs-devops-standards`) and
  `gcl-ui-components` (`v1.6.0` / `v4.3.2`, recorded `rc: skipped`, which is not `0`). Those three
  need their pair normalised first.

## Steps

1. Rewrite the `uses:` pin to `@v1.5.0`. — done
2. Append the `[Unreleased]` CHANGELOG bullet, per Rule 6. — done
3. Commit on `spike/issue-165-repin-ssot-linter-v1-5-0`, push, open a PR referencing
   [GenCr-ft/gcd-shared-actions#165](https://github.com/GenCr-ft/gcd-shared-actions/issues/165).
4. Confirm the SSoT Compliance Check is green **and** that the run resolved the workflow at
   `v1.5.0` — a green check alone does not prove which tag executed, which is the whole reason
   this issue exists.

## Acceptance

```gherkin
Scenario: this consumer executes the v1.5.0 reusable workflow
  Given .github/workflows/ssot-compliance.yml pinned reusable-ssot-linter.yml@v1.3.8
  When the pin is rewritten to @v1.5.0 and the PR check runs
  Then the SSoT Compliance Check completes green
  And the run resolved the reusable workflow at tag v1.5.0

Scenario: the validated Law version is unchanged
  Given governance-version v1.6.1 and tooling-version v4.4.1 before the change
  When the diff is inspected
  Then both values are byte-identical to their previous content
  And continue-on-error is byte-identical
```

## Note on the gate that blocked this sweep

The first commit attempt aborted in 26 of 27 repositories with
`ModuleNotFoundError: No module named 'yaml'` from the traceability gate, because `python3` on
`PATH` resolves to `~/.gft-studio/.poetry/bin/python3`, which has no PyYAML, while
`/usr/bin/python3` carries 6.0.1. That is the W1 defect of
[GenCr-ft/gcs-project-management#585](https://github.com/GenCr-ft/gcs-project-management/issues/585)
reproducing 26 times in a single sweep. Resolved by giving the gate a capable interpreter — never
by skipping it.
