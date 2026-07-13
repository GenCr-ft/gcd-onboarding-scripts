---
docId: GOV-PLAN-243
title: "[CODE] Launcher --smoke-exit-after-spawn for F1.5 E2E boot proof"
status: approved
github-issue: GenCr-ft/gcd-onboarding-scripts#243
issue-id: GenCr-ft/gcd-onboarding-scripts#243
---
## [CODE] Launcher --smoke-exit-after-spawn (F1.5)

Add the boot-proof smoke-exit contract to workspace/run-walking-skeleton.sh per
the Forge interface decision (gcs-project-management#414 §6.2), so the F1.5 E2E
harness can drive the launcher and assert a clean exit after boot proof.

### Fix (Forge's 5 hook-ins)
1. Arg-parse --smoke-exit-after-spawn → SMOKE_EXIT=true; init AUTH_PID/GAME_PID="" early.
2. Smoke-mode traps: `trap _cleanup EXIT` + `trap 'echo CLEAN_EXIT; exit 0' TERM`
   (default: trap _cleanup EXIT INT TERM unchanged).
3. Exit-code map: 1 port / 2 docker / 3 build / 4 service-crash / 5 unreachable / 6 smoke-timeout.
4. Emit `AETHEL_BOOT_PROOF:SERVICES_READY` after the game-server /health check (smoke mode).
5. Replace final `wait` with: smoke → sleep watchdog (TERM→exit 0 CLEAN_EXIT; timeout→exit 6 TIMEOUT); else wait.

### Verification
- tests/test_walking_skeleton_launcher.sh: arg parsing, sentinel strings, exit-code
  constants, backward-compat (no-flag path unchanged). `bash -n` clean.
- Full boot E2E = the harness (separate F1.5 WI).

### TDD cycles
- WI-243.1 red/green — smoke-exit assertions + Forge hook-ins.
