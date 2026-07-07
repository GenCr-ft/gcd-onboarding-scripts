---
docId: GOV-PLAN-229
title: "[CODE] Self-bootstrap pyenv/nvm + prettier; graceful python fallback"
status: approved
issue-id: GenCr-ft/gcd-onboarding-scripts#229
---

## [CODE] Installers self-bootstrap + graceful degradation

Parent gcs-project-management#377; unblocks full one-liner (gencr-ft.github.io#38).

- [x] install_node: auto-install nvm if absent
- [x] install_python: auto-install pyenv; compile pinned version only when deps satisfiable; else graceful fallback to system python3 >= 3.9 (loud WARN); never abort
- [x] install_prettier: npm global (non-blocking)
- [x] tests: test_installer_bootstrap.sh; updated AC-3 in test_installer_error_remediation_211.sh
- [x] verified REAL: pyenv bootstrap works; fast fallback on dep-missing/no-sudo host
