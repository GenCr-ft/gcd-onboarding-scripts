---
docId: GOV-PLAN-213
title: "[CODE] fix(installers): WI-213 — comprehensive installer error-handling"
github-issue: GenCr-ft/gcd-onboarding-scripts#213
issue-id: GenCr-ft/gcd-onboarding-scripts#213
status: in-progress
created: '2026-06-29'
scope: installer-error-handling-comprehensive
---

# [CODE] WI-213 — comprehensive installer error-handling

## Summary
Fix install_rustup, install_wasm_pack, install_wasm_bindgen_cli, install_commitlint,
install_hook_managers, opentofu dispatcher, and configure_gft_cli to emit structured
[ERROR]/[WARN] with remediation instead of claiming [SUCCESS] on failure.

## TDD Cycles

### Cycle 1 — AC-1: rustup curl|sh failure → [ERROR] + rustup.rs URL
- RED: stub curl to exit 1, assert rustup.rs URL in output, no [SUCCESS]
- GREEN: wrap curl|sh in if ! block

### Cycle 2 — AC-2+AC-3: rustup chains fail → no [SUCCESS]
- RED: two-phase stub (new-install path); stub rustup update to exit 1 (existing-path)
- GREEN: if/else around both chains

### Cycle 3 — AC-4: cargo install fails → no [SUCCESS]
- RED: stub cargo to exit 1, assert no success message
- GREEN: if/else around wasm-pack and wasm-bindgen-cli

### Cycle 4 — AC-5: commitlint/hook_managers npm failure → no [SUCCESS]
- RED: stub npm to exit 1
- GREEN: if/else in commitlint; any_failed flag in hook_managers

### Cycle 5 — AC-6: opentofu dispatcher || trap → no false [WARN]
- RED: stub install_binary_from_github to fail, assert no "No version" warn
- GREEN: replace || with if/else

### Cycle 6 — AC-7+AC-8: configure_gft_cli PATH guidance
- RED: full gcs-plt-tools fixture, assert source ~/.bashrc and export PATH guidance
- GREEN: append guidance block to configure_gft_cli
