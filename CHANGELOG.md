# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Extend agent bootstrap logic to support global ~/.antigravity/ paths and bundle work-item-refinement skill. (#68, @Antigravity)
- Align workspace onboarding bundle with bounded workspaces, adding workspace-aware test-all.sh selectors and poetry-independent workspace.sh fallbacks. (#77, @Antigravity)

### Fixed
- Correct workspace planning init path and add deployment regression coverage. (#71, @loigallain)
- Aligned `install_gft_cli()` with the workspace-managed `gcs-plt-tools` wrapper contract by deferring pre-clone installs and delegating post-clone installation to `gcs-plt-tools/onboard.sh`. (#95, @loigallain)
