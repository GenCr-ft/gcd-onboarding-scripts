---
docId: GOV-PLAN-546
title: "[CODE] WI-546 — bound CI jobs and add a concurrency group"
issue-id: GenCr-ft/gcs-project-management#546
status: approved
---

# [CODE] WI-546 — bound CI jobs and add a concurrency group

Implementation record for [GenCr-ft/gcs-project-management#546](https://github.com/GenCr-ft/gcs-project-management/issues/546),
one PR per repo. Tier `wi:lightweight` (human-set), so DESIGN is waived and the decisions are recorded here.

## The defect

Every job in this repo's `ci.yml` was **unbounded** — no `timeout-minutes` — and the workflow had no
`concurrency` group. A hung job therefore occupies a runner until GitHub's 6-hour ceiling, and pushing
three commits queues three full runs. On a single-lane self-hosted runner that is the dominant source of
lost capacity: 52% of measured occupancy came from 9 unbounded hangs.

## Decisions

**Budgets are per job and sized from measurement, not uniform.** Fleet median job is 21s and p90 is 81s,
so the values applied here are generous by more than an order of magnitude. They exist to bound a hang,
not to police runtime — a tight budget would convert a slow run into a flaky failure across 13 repos at
once.

**`main` is never cancelled.**

```yaml
cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

Applied uniformly rather than per repo. A keyword scan suggested two repos published releases; on
inspection every match was a Godot **download** URL (`godotengine/godot/releases/download/…`), not a
publishing step. Since no in-scope workflow publishes a release, and several upload CI artefacts, the
conservative rule — never cancel `main` — satisfies the issue's "exclude main where a run publishes"
condition everywhere with one identical stanza that reviewers can compare across all 13 PRs.

**Rejected: a uniform 20-minute budget for every job.** Cheaper to review, but it tells a reader nothing
about what the job does, and it over-budgets the 10-second lint jobs where a hang is most detectable.

**Rejected: `cancel-in-progress: true` unconditionally.** Would cancel a main-branch run mid-artefact-upload.

## Scope

Only `timeout-minutes` and `concurrency`. No gate's assertions change, no test-suite performance work.

## Verification

- `ci.yml` still parses as YAML
- every job carries the intended budget, asserted against an explicit per-job table
- the concurrency stanza matches the fleet-standard form exactly
- the diff touches nothing but `ci.yml`, this plan, and `CHANGELOG.md`

## Execution

- [x] Survey: 13/13 repos, 26 jobs, 0 bounded, 0 with a concurrency group, 16 jobs on the single lane
- [x] Apply budgets + concurrency
- [x] Verify parse, budgets, stanza, and diff scope
- [ ] PR linked to the keystone issue
