# Findings & Decisions

## Requirements
- Issue: https://github.com/GenCr-ft/gcd-onboarding-scripts/issues/113
- Objective: repair the documented first-run onboarding path.
- Scope: shell orchestration, workspace path consistency, role parsing, SSH setup, documentation filename/invocation drift, and smoke test coverage.
- Out of scope: changing governance SSoT schema, adding new role definitions, changing `gcs-plt-tools` ownership, or performing real workstation package installation.

## Research Findings
- `main()` calls `detect_os`, but no such function is defined; `detect_os_arch` exists in `includes/02_installers.sh`.
- `setup_ssh_key` writes to `$HOME/.ssh/id_ed25519` without ensuring `$HOME/.ssh` exists.
- `configure_environment_variables` reads `$2` under `set -u`; `main()` passes only one argument.
- `select_user_role` emits log output to stdout, so command substitution captures log text in the selected role.
- `clone_repositories_for_role` hardcodes `$HOME/gft_studio`, while later phases use `GFT_PROJECTS_HOME`.
- README and AGENTS advertise `bash gft-onboarding.sh [--role <role-name>]`, but argument parsing does not exist.
- README advertises standalone `curl` download plus `.sha256` files; the script requires `includes/`, and checksum files are not present in the repo.
- `onboarding-win.ps1` expects `gft_onboarding.sh`; repo file is `gft-onboarding.sh`.
- README/docs reference `validate-gft-devops-environment.sh`; repo file is `validate-devops-environment.sh`.
- Existing tests pass, but they do not exercise the real `main()` path deeply enough.

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| Implement `--role` parsing in `gft-onboarding.sh`. | Documentation already promises this behavior, and it is low-risk. |
| Keep `GFT_ROLE` support. | Existing tests and automation use it. |
| Make docs say to clone/download the full repo, not one file. | Current script is modular and sources `includes/`. |
| Add a smoke test that sources `gft-onboarding.sh` and calls `main` with stubs. | This catches orchestration drift without network or package installs. |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| Restricted environment cannot resolve GitHub during direct smoke run. | Use local stubs/mocks in tests; do not rely on external network. |

## Resources
- Repo AGENTS: `AGENTS.md`
- Workspace status: `gcs-project-management/workspaces/workspace-ops/STATUS.md`
- Main script: `gft-onboarding.sh`
- Helper scripts: `includes/*.sh`
