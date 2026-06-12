# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Add install_gft_ops_scripts to ensure idempotent pipx installation of gft-ops-scripts during onboarding. (#308, @Antigravity)
- Extend agent bootstrap logic to support global ~/.antigravity/ paths and bundle work-item-refinement skill. (#68, @Antigravity)

- Align workspace onboarding bundle with bounded workspaces, adding workspace-aware test-all.sh selectors and poetry-independent workspace.sh fallbacks. (#77, @Antigravity)

### Fixed
- Repair first-run onboarding orchestration, workspace path handling, and documentation drift. (#113, @loigallain)
- Correct workspace planning init path and add deployment regression coverage. (#71, @loigallain)
- Aligned `install_gft_cli()` with the workspace-managed `gcs-plt-tools` wrapper contract by deferring pre-clone installs and delegating post-clone installation to `gcs-plt-tools/onboard.sh`. (#95, @loigallain)
- Updated the shipped workspace `AGENTS.md` bundle to match bounded-workspace docs, the installed planning init path, and current Phase 6 wording. (#96, @loigallain)
