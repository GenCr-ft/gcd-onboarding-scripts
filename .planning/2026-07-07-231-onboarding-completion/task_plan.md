---
docId: GOV-PLAN-231
title: "[CODE] Onboarding completion — idempotent agent provisioning + non-fatal SSH upload"
status: approved
issue-id: GenCr-ft/gcd-onboarding-scripts#231
---

## [CODE] Final completion fixes

Parent gcs-project-management#377; found via real end-to-end run of #40.

- [x] provision_agent_files: `-ef` guard + rm-f/relink → idempotent (no 'File exists' abort; safe with dir-symlink homes)
- [x] setup_ssh_key: SSH upload failure downgraded to non-fatal WARN (HTTPS clones work)
- [x] regression test test_agent_provisioning_idempotent.sh
- [x] verified isolated-home suite green; follow-up filed for test GFT_PROJECTS_HOME isolation
