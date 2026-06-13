# Progress

## 2026-06-13

- Refined `GenCr-ft/gcd-onboarding-scripts#115` after the user required the work-item lifecycle and issue refinement gate.
- Created design sub-issue `GenCr-ft/gcd-onboarding-scripts#116`, posted the implementation plan on `#115`, then closed `#116`.
- Added a red regression suite for workspace quickstart parsing.
- Implemented `parse_cli_args` with support for:
  - `--quickstart --workspace <id>`
  - `--workspace=<id>`
  - `--role <role>`
  - `--sync-hooks`
  - `--help`
- Added bounded workspace helpers for:
  - `aethel`
  - `evai-platform`
  - `agent-factory`
  - `workspace-ops`
  - `studio-gencraft`
- Merged workspace repository bundles into the role-based clone list.
- Corrected the Windows wrapper to launch `gft-onboarding.sh` and forward quickstart parameters.
- Updated README quickstart instructions and changelog entries.
- Verification:
  - `bash tests/test_onboarding_logic.sh` passed.
  - `bash ./test.sh` passed.
