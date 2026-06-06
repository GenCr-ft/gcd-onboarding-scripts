# Findings

- `install_gft_cli()` currently creates `~/.local/share/gft/venv` and symlinks `~/.local/bin/gft` to that isolated environment.
- The main orchestrator runs `install_tools_for_role` before `clone_repositories_for_role`, so `gcs-plt-tools` source may not exist when `install_gft_cli()` is first called.
- `configure_gft_cli()` and `final_validation()` already form a post-clone phase where `gft` availability is checked and environment is wired.
- `gcs-plt-tools/onboard.sh` now owns the wrapper/config lifecycle and already guards against replacing foreign `~/.local/bin/gft` installs.
