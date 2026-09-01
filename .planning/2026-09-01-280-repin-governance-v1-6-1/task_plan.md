---
docId: GOV-PLAN-280
title: '[CODE] WI-280 — re-pin all three SSoT pins (wave 2)'
issue-id: GenCr-ft/gcd-onboarding-scripts#280
status: complete
version: "1.0"
authors: [session-agent]
creation_date: '2026-09-01'
last_updated_date: '2026-09-01'
language: en
summary: >
  Wave 2 of the fleet SSoT re-pin. Moves all three pins; this repo was held out of wave 1 by the exit-2 that v1.6.1 removes.
metadata:
  scope: workspace-ops
  domain: governance
  doc-type: plan
  lifecycle-stage: complete
  security-classification: l2_confidential
  keywords: [ssot-gate, version-pin, delivery, fleet-sweep, pin-parity-rule]
---

# [CODE] WI-280 — re-pin all three SSoT pins (wave 2)

## The change — three pins, one PR

```yaml
uses: …/reusable-ssot-linter.yml@v1.3.4   ->  @v1.3.8
tooling-version: "v4.3.2"                 ->  "v4.4.1"
governance-version: "v1.6.0"                   ->  "v1.6.1"
```

Combined deliberately. This repo was **held out of wave 1** by the very exit-2 that `v1.6.1` removes,
so splitting it into two WIs would mean two lifecycle gates and two CI rounds on a single-runner queue
for one review.

## Why this repo was held, and why it no longer is

It is **`continue-on-error: false`** — blocking. In wave 1 that meant the pin rule's exit 2 was not
masked: `Check Tool-Version Pin Outcome` runs when `continue-on-error == false` and fails the job.
Four repos were pulled from wave 1 on that basis **after the pilot exposed it**, this one among them.
Had the sweep gone ahead as first planned, they would have gone red for a cause nobody had identified.

`v1.6.1` removes the cause rather than masking it: `gcs-core-governance@v1.6.1` carries
`poetry 2.4.1`, read at the tag and absent at `v1.6.0`.

## Measured before proposing

Off-runner across all 30 consumers at governance `v1.6.1` + tooling `v4.4.1`: **30 of 30 exit 0,
clean.** This repository is one of them. Since it is blocking, that is not a convenience — it is the
precondition.

Shared reasoning: [gcd-shared-actions#165](https://github.com/GenCr-ft/gcd-shared-actions/issues/165).

## Not changing

`continue-on-error` (`GOV-STAN-010` §5.6), and every pre-existing finding in any other workflow.

## Acceptance — stricter here than Group A

No mask, so CI must genuinely pass:

- [x] All three pins moved; `continue-on-error` byte-identical.
- [ ] `SSoT Compliance Check` **green** on the head SHA, verified SHA-filtered — not "green because
      masked", which is unavailable here anyway.
- [ ] `Verify tool-version pins` **succeeds**. On a blocking consumer a non-zero exit fails the job,
      so this is the criterion and not a footnote.
- [ ] `Linter scanned N file(s)` present and **non-zero** — a zero scan trips the WI-111 guard and
      hard-fails. Two consumers are held out of this sweep for exactly that reason.
- [ ] Any pre-existing failure in another workflow attributed to `main` **by shape** before merging —
      same failing jobs, same failing steps at the merge base. "Main is generally red" licenses
      nothing.
