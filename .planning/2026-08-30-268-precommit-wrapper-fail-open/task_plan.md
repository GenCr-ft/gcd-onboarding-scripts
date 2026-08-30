---
docId: GOV-PLAN-268
title: WI-268 — precommit wrapper fail open
issue-id: GenCr-ft/gcd-onboarding-scripts#268
status: in_progress
---

# [CODE] WI-268 — precommit wrapper fail open

Implementation plan for GenCr-ft/gcd-onboarding-scripts#268 — **Stage A only**, the generator. The
34-clone sweep is a separate PR.

## Problem

`deploy_planning_metadata_hook` in `includes/06_workspace_files.sh` has three defects.

**1. The wrapper fails open.** It delegates to `pre-commit.legacy` if present and `exit 0`s
otherwise. Legacy exists only where an existing hook was moved aside, so a clone where
`pre-commit install` never ran gets `exit 0` by default.

**2. The `commit-msg` stage is never installed.** Nothing writes it. Compounding it,
`pre-commit run --all-files` — the command `AGENTS.md` §4 gives for running hooks manually —
skips commit-msg-stage hooks by design, so the manual check reports green over a set excluding
`commitlint`.

**3. The skip branch greps a version-less marker**, so the exact population needing repair —
wrapper present, no legacy — is the population it skips. Re-running onboarding cannot fix the fleet.

### Measured, all 34 clones

```
with .pre-commit-config.yaml          : 34/34
wrapper AND legacy (so hooks DO run)  :  0/34
wrapper, NO legacy (FAILS OPEN)       : 30/34
commit-msg hook installed             :  0/34
declare hooks but nothing runs them   : 33/34
```

**The wrapper's presence is anti-correlated with hooks running.** The one clone whose declared set
runs is `gencr-ft.github.io`, and it runs *because* `pre-commit install` displaced the wrapper into
`.legacy`. That clone is therefore already in the recursion precondition.

## Design

Approved as [#270](https://github.com/GenCr-ft/gcd-onboarding-scripts/issues/270).

**Ordering constraint:** the versioned marker lands in the same change, first. Without it the fix is
unreachable by re-running onboarding.

The wrapper becomes graduated rather than binary:

| Condition | Wrapper does |
|---|---|
| legacy present and **not self** | delegate, propagate exit code |
| no legacy, config present, `pre-commit` on PATH | run the declared set directly |
| no legacy, config present, `pre-commit` **absent** | **fail closed**, naming the binary |
| no config at all | `exit 0` — nothing is declared |

Plus a self-call guard, and `pre-commit install --hook-type commit-msg` **only** — never
`--hook-type pre-commit`, which is what creates the recursion.

## Corrections to the design and plan, made before implementing

Two inherited claims about **how to test** were measured and refuted. Recorded because both were
labelled "confirmed" before being run:

1. **Dispatch is not required.** This repo's own tests source the includes and call functions
   directly (`tests/test_onboarding_logic.sh`). Verified: sourcing `01_helpers.sh` +
   `06_workspace_files.sh` and calling `deploy_planning_metadata_hook` runs the generator and writes
   the wrapper. The dispatch entry point is **dropped from scope** — adding an unused invocation
   surface inside a full-tier change to enforcement code, justified by a refuted claim, is scope
   creep. AC-10 is withdrawn with it.
2. **A nonexistent function is loud, not silent.** `deploy_hooks` exits **127** with
   `command not found`, not 0. It becomes `exit 0` only under `|| true` — so the silent-pass risk
   lives in a harness's error handling, not in the generator's shape, and would have been fixed in
   the wrong place.
3. **Not bats.** This repo's `test.sh` discovers `tests/test_*.sh`; CI runs `bash test.sh`. Bats
   1.13.0 is installed, which is presumably how the wrong convention entered the plan.

What survived: there is no `deploy_hooks` function, and the real entry point is
`deploy_planning_metadata_hook`. The warning was worth having — it is why this was caught here.

**Pattern worth noting:** the plan's findings about the *generator* have held up under measurement
every time; its findings about the *harness* have not.

## Acceptance criteria

| AC | Arm | Assertion |
|----|-----|-----------|
| AC-1 | must-fire | a clone that never ran `pre-commit install` does not pass everything |
| AC-2 | must-fire | a v1 wrapper with no legacy is **rewritten**, not skipped |
| AC-3 | must-fire | `.git/hooks/commit-msg` exists after deployment |
| AC-5 | must-fire | a delegate carrying the wrapper's own marker is refused, without recursing |
| AC-6 | must-fire | config present and `pre-commit` absent → non-zero, naming the binary |
| AC-8 | green-state guard | no config at all → exit 0 |
| AC-9 | green-state guard | a current-version wrapper with no legacy is skipped — idempotence |

AC-4 (non-conventional header rejected) needs a real `commitlint` and belongs with the commit-message
content rule in WI-A4; AC-7 (clean commit in three stacks) is a fleet observation and belongs to
Stage B. Both are recorded as deferred rather than silently dropped.

**AC-8 and AC-9 are labelled green-state guards before the run, not after.** This programme has
mislabelled a must-fire arm four times.

## Cycles

| Cycle | Commit | State |
|-------|--------|-------|
| red | `test(hooks): WI-268.1 — red: the wrapper fails open and commit-msg is never installed` | done |
| green | `fix(hooks): WI-268.2 — green: versioned wrapper, direct run, commit-msg stage` | pending |
| blue | only if earned | n/a |

## Out of scope

Stage B (the 34-clone sweep). WI-A4's commit-message content rule. The two orphaned July
`.planning/` folders untracked in this repo — a Rule 4 finding of their own.
