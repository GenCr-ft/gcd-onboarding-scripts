# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Brought the blocking SSoT gate to zero findings: added compliant frontmatter to three documents that had none, repaired `DVO-SPEC-001`'s frontmatter (its `docId` was a prose title), renamed all four to the `<docId>.<description>.md` form, and moved the two inbound references (`README.md`, TEST SUITE 13). Re-pinned `governance-version` from the ambiguous `v1.4.0` — a tag carried by both the archived `gcs-devops-standards` and the live `gcs-core-governance` — to `v1.6.0`, which exists only in the live Law; measured delta 0 errors over scanned=4 at both tags. (#260, @loigallain)
- Bound every `ci.yml` job with `timeout-minutes` and added a workflow `concurrency` group that cancels superseded branch runs but never `main`. (#546, @loigallain)

### Added
- Add workspace quickstart onboarding for bounded newcomer workspaces. (#115, @loigallain)
- Add install_gft_ops_scripts to ensure idempotent pipx installation of gft-ops-scripts during onboarding. (#308, @Antigravity)
- Extend agent bootstrap logic to support global ~/.antigravity/ paths and bundle work-item-refinement skill. (#68, @Antigravity)
- Align workspace onboarding bundle with bounded workspaces, adding workspace-aware test-all.sh selectors and poetry-independent workspace.sh fallbacks. (#77, @Antigravity)
- Build the local gcl-voxel-engine package and validate its main and types entrypoints in the run-walking-skeleton.sh launcher before building gcp-aethel-server. (#236, @Antigravity)

### Fixed
- Replace archive download install blocks with `git clone` in README and `docs/auxiliary-scripts.md`; remove dangling `.sha256` references; add `Set-ExecutionPolicy` bypass to Windows install block (#172, PR #178, @loigallain)
- Correct the Windows onboarding wrapper to launch `gft-onboarding.sh`. (#115, @loigallain)
- Correct workspace planning init path and add deployment regression coverage. (#71, @loigallain)
- Aligned `install_gft_cli()` with the workspace-managed `gcs-plt-tools` wrapper contract by deferring pre-clone installs and delegating post-clone installation to `gcs-plt-tools/onboard.sh`. (#95, @loigallain)
- Updated the shipped workspace `AGENTS.md` bundle to match bounded-workspace docs, the installed planning init path, and current Phase 6 wording. (#96, @loigallain)
- Isolate onboarding test suite HOME environment to prevent host state leakage. (#236, @Antigravity)
