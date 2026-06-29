---
docId: GOV-PLAN-211
title: "[CODE] fix(installers): WI-211 — installer error-handling & remediation guidance"
github-issue: GenCr-ft/gcd-onboarding-scripts#211
issue-id: GenCr-ft/gcd-onboarding-scripts#211
status: in-progress
created: '2026-06-29'
scope: installer-remediation-guidance
---

# [CODE] WI-211 — installer error-handling & remediation guidance

## Summary
Fix `install_node`, `install_python`, `install_tool` dispatcher (node-lts/python), and
`setup_ssh_key` to emit structured [ERROR] with actionable remediation on failure instead
of claiming [SUCCESS].

## TDD Cycles

### Cycle 1 — AC-1: empty version guard in install_node + sed fix
- RED: assert install_node "" emits "check role tooling matrix" and no [SUCCESS]
- GREEN: add empty-string guard; fix sed s/-/\//

### Cycle 2 — AC-2: nvm chain failure → no [SUCCESS]
- RED: assert install_node "20.0.0" with failing nvm emits [ERROR] and no [SUCCESS]
- GREEN: wrap nvm chain in if/else

### Cycle 3 — AC-3: pyenv missing → [ERROR] + install URL; dispatcher || fix
- RED: assert install_python "3.11" with no pyenv in PATH emits pyenv.run URL
- GREEN: fix install_python error handling + fix dispatcher || for node-lts and python

### Cycle 4 — AC-4: gh scope error → guidance
- RED: assert setup_ssh_key with failing gh emits gh auth refresh guidance
- GREEN: capture gh_exit, emit auth refresh command on failure
