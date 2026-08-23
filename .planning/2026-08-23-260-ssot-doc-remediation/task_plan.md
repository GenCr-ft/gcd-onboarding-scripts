---
docId: GOV-PLAN-260
title: '[CODE] WI-260 — SSoT doc remediation + v1.6.0 re-pin'
issue-id: GenCr-ft/gcd-onboarding-scripts#260
status: complete
---

# [CODE] WI-260 — SSoT doc remediation + v1.6.0 re-pin

Implementation plan for GenCr-ft/gcd-onboarding-scripts#260, with the `v1.6.0` re-pin from
GenCr-ft/gcs-core-governance#342 folded in — same gate, same repo, and the remediation is what makes
the re-pin land green.

## Measured state before the change

Harness: `git archive origin/main` into an empty root, pruned with CI's own 26-name `excluded_dirs`
list read out of `gcd-shared-actions/scripts/prepare-ssot-scan-root.sh`; Law worktrees at tags
`v1.4.0` and `v1.6.0`; engine `gcd-ops-scripts@v4.3.2`.

| Law tag | scanned | errors |
|---|---|---|
| `v1.4.0` (old pin) | 4 | 5 |
| `v1.6.0` (new pin) | 4 | 5 |

Delta **0**. Reproduces this WI's own AC-1 count of 5 exactly.

**Positive guard.** The linter output must contain the marker `SSoT Linter Report` or the row is
recorded `INVALID` — never `0`. The parent issue's original table reported this repo as
`scanned=0, err=0` because a stale venv path made every invocation exit 127 and `${VAR:-0}` defaulting
rendered the silence as a clean repo. No `${VAR:-0}` appears in this harness, and the exit code is
written to a file and read back rather than taken through a pipe.

## The 5 findings and the 4 files

| File | Validator | Defect |
|---|---|---|
| `spec/gft-developer-onboarding-specification.md` | `SCHEMA_VALIDATOR` | `creation_date` missing |
| `spec/gft-developer-onboarding-specification.md` | `NAMING_VALIDATOR` | filename ≠ `<docId>.<description>.md` |
| `docs/auxiliary-scripts.md` | `ENGINE_PARSER` | no frontmatter mapping |
| `docs/superpowers/plans/2026-06-14-preflight-env-readiness.md` | `ENGINE_PARSER` | no frontmatter mapping |
| `docs/superpowers/specs/2026-06-14-preflight-env-readiness-design.md` | `ENGINE_PARSER` | no frontmatter mapping |

Two masking effects mean 5 findings did not cost 5 edits:

1. `SCHEMA_VALIDATOR` emits **one error per file**, so `creation_date` hid the rest of the required
   set (`version`, `authors`, `last_updated_date`, `knowledgeGuardian`, `ssot_path`, `metadata`).
2. `ENGINE_PARSER` short-circuits every downstream validator. Giving the three parser failures a
   frontmatter block *created* naming and taxonomy obligations that were previously unreachable.

`spec/…-specification.md` was the worst case: its `docId` was the prose string
`G@FT.ai Developer Onboarding Script & Tooling Standardization`, which cannot satisfy the schema
pattern `^[A-Z]{3,}-[A-Z]{2,10}(-[A-Z]{2,10})*-[0-9]{3,}$`.

## Changes

| Old path | New path | docId |
|---|---|---|
| `spec/gft-developer-onboarding-specification.md` | `spec/DVO-SPEC-001.gft-developer-onboarding-specification.md` | `DVO-SPEC-001` |
| `docs/auxiliary-scripts.md` | `docs/DVO-REFE-001.auxiliary-scripts.md` | `DVO-REFE-001` |
| `docs/superpowers/plans/2026-06-14-preflight-env-readiness.md` | `docs/superpowers/plans/DVO-PLAN-001.preflight-env-readiness.md` | `DVO-PLAN-001` |
| `docs/superpowers/specs/2026-06-14-preflight-env-readiness-design.md` | `docs/superpowers/specs/DVO-TDD-001.preflight-env-readiness-design.md` | `DVO-TDD-001` |

`DVO` is the `studio_domain` code for `devops-and-infrastructure`, which is the taxonomy
`skos:prefLabel` these documents carry. Note that `domain: engineering` — as still written in this
repo's `README.md` — is **not** a valid value under the live Law; the README never fails only because
its basename is dropped by the engine's `ignored_files`.

### Inbound references moved with the rename

Renaming `docs/auxiliary-scripts.md` is not free. Two live references had to move:

- `README.md` — the "Auxiliary Scripts" pointer.
- `tests/test_onboarding_logic.sh` — TEST SUITE 13
  (`test_auxiliary_scripts_windows_invocation_uses_clone`) resolves the file by path and greps its
  content. Renaming without this edit turns a passing suite red.

The other three files have no inbound references outside `.planning/` prose.

## Verification

1. Re-measure the branch through the same prep at **both** Law tags: expect `scanned=4, errors=0`.
2. **Must-fail control** — the zero must be shown capable of being non-zero: delete the
   `knowledgeGuardian` line from one remediated file in the materialised scan root and confirm the
   linter fires, then restore and confirm it goes clean. A "0 findings" with no must-fail control is
   not evidence; it is indistinguishable from a linter that never ran.
3. `bash test.sh` — TEST SUITE 13 must still pass against the renamed path.
4. AC-2 assertion by parsing, not grep: `governance-version` must be the only differing key between
   `origin/main` and this branch anywhere in the document; `uses:`, `continue-on-error` and
   `tooling-version` byte-identical.

## Out of scope

- Flipping the gate — already `continue-on-error: false`, and it stays that way.
- `README.md` / `AGENTS.md` / `CHANGELOG.md` frontmatter — linter-exempt via `ignored_files`; they
  cannot fail the gate, so correcting their stale `domain: engineering` belongs elsewhere.
- `GenCr-ft/gcd-onboarding-scripts#261` — the SSoT gate has never actually executed here; all 9 runs
  are zero-job startup failures. Independent of document content, tracked separately.

## Refs

Work item `GenCr-ft/gcd-onboarding-scripts#260` · fleet re-pin
`GenCr-ft/gcs-core-governance#342` · parent programme `GenCr-ft/gcs-core-governance#314` ·
dual-tag defect `GenCr-ft/gcd-shared-actions#125`.
