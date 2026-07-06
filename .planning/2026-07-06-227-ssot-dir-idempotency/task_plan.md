---
docId: GOV-PLAN-227
title: "[CODE] setup_ssot_repository idempotency for stale non-git dir"
status: approved
issue-id: GenCr-ft/gcd-onboarding-scripts#227
---

## [CODE] SSoT dir idempotency

Parent Initiative gcs-project-management#377; unblocks fully-working one-liner (gencr-ft.github.io#36).

### TDD

- [x] RED: tests/test_ssot_setup_idempotency.sh (valid-clone→pull, stale-non-git→re-clone, absent→clone)
- [ ] GREEN: gate on `$GFT_SSOT_PATH/.git`; if dir exists without .git, rm -rf then clone
