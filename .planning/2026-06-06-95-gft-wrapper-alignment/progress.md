# Progress

## 2026-06-06

- Created clean worktree `wi-95-gcd-onboarding-scripts` on branch `feat/issue-95-gft-wrapper-alignment`.
- Confirmed the current conflict source is `includes/02_installers.sh:install_gft_cli()`.
- Confirmed this repo should delegate actual wrapper ownership to `gcs-plt-tools/onboard.sh` instead of maintaining a second installer model.
- Implemented delegated `gft` installation:
  - pre-clone calls now defer cleanly when `gcs-plt-tools/onboard.sh` is not present yet
  - post-clone calls delegate to `gcs-plt-tools/onboard.sh`
  - `configure_gft_cli()` now repairs/installs `gft` before exporting workspace variables
- Updated repo docs and changelog to reflect the single-owner wrapper model.
- Added onboarding logic coverage for:
  - deferred install before repo clone
  - delegated install after clone
  - `configure_gft_cli()` bootstrapping the CLI
- Validation:
  - `bash tests/test_onboarding_logic.sh` passes
  - `bash test.sh` still fails due to unrelated workspace bundle drift; captured as `GenCr-ft/gcd-onboarding-scripts#96`
