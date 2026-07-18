---
docId: GOV-PLAN-247
title: WI-247 — configure_gft_cli defers to config.env (stop shadowing)
issue-id: GenCr-ft/gcd-onboarding-scripts#247
status: in_progress
---

# [CODE] WI-247 — configure_gft_cli sources config.env

Implementation plan for GenCr-ft/gcd-onboarding-scripts#247. Design: #248.

- [ ] configure_gft_cli ensures the managed GENCRAFT block sources config.env as its final line (idempotent)
- [ ] stop writing the ~/gft_studio default; write explicit GFT_PLT_ROOT/GFT_WORKSPACE only when config.env absent
- [ ] keep explicit GFT_SSOT_GEMOP_PATH (studio-home derived; not in config.env)
- [ ] SUITE 6d test (config.env present → source line once + config.env value wins + no hardcoded GFT_WORKSPACE); 6b/6c unaffected
