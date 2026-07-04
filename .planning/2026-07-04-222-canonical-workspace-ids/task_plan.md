---
docId: GOV-PLAN-ONB-222
title: "[CODE] Orchestrator — 4 canonical workspace ids + legacy aliases (ENG-ADR-087)"
status: approved
issue-id: GenCr-ft/gcd-onboarding-scripts#222
---
## [CODE] Orchestrator: 4 canonical workspace ids + aliases

Parent Initiative: GenCr-ft/gcs-project-management#377. Decision: ENG-ADR-087. Keystone consumer: GenCr-ft/gencr-ft.github.io#26.

### TDD Cycles
- [x] Cycle 1 — RED: tests/test_canonical_workspaces.sh (4 canonical valid, aliases canonicalize, unknown rejected, help lists canonical)
- [ ] Cycle 1 — GREEN: 01_helpers.sh canonicalize_workspace + valid_workspaces/is_valid_workspace/workspace_role/workspace_repositories/print_usage → 4 canonical + aliases; parse_cli_args canonicalizes GFT_WORKSPACE; 07_preflight.sh case
- [ ] Cycle 2 — update existing test_workspace_quickstart_contract to canonical ids
- [ ] BLUE: refactor alias map to a single source

### Canonical → repos
- aethel: gcp-aethel-server/client/pcg, gcl-srv-authentication, gcl-srv-persistence, gcp-aethel-backlog
- gft-platform: gcs-plt-tools, gcs-plt-docs-req, gcs-plt-architecture, gcs-core-governance, gcs-engineering-handbook, gcs-security-core, gcs-studio-legal, gcs-project-management, gencr-ft.github.io
- onboarding: gcd-onboarding-scripts, gcd-ops-scripts, gcd-shared-actions, gencraft-iac
- agent-ecosystem: gcs-plt-gemop, gcs-plt-gembp

### Aliases
evai-platform→gft-platform, workspace-ops→onboarding, agent-factory→agent-ecosystem, studio-gencraft→gft-platform
