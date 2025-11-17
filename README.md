---
title: GenCr@t Studio Onboarding Script Suite
status: Active
owners:
  - GCS DevOps Enablement Guild
last_reviewed: 2025-06-26
---

# GenCr@t Studio Onboarding Script Suite

## Table of Contents
- [Purpose for AI Agents](#purpose-for-ai-agents)
- [Features](#features)
- [Dependencies (gcs-devops-standards paths)](#dependencies-gcs-devops-standards-paths)
- [Script Modules & Commands](#script-modules--commands)
- [Execution Flow](#execution-flow)
- [Platform-Specific Launch Procedures](#platform-specific-launch-procedures)
- [Diagnostics & Support](#diagnostics--support)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Knowledge Base Discoverability](#knowledge-base-discoverability)
- [Linked Documentation](#linked-documentation)

## Purpose for AI Agents
This repository is the approved single source of truth (SSoT) for onboarding developers—human or AI copilots—into GenCr@t Studio. All automation must:

1. Pull standards exclusively from `gcs-devops-standards` so that the runtime stays compliant.
2. Run idempotently, surfacing every action to the operator through logs (`~/gft_onboarding_YYYY-MM-DD_HH-MM-SS.log`).
3. Respect the role matrix so GEM agents never install tooling that is not sanctioned for their persona.

If you are orchestrating onboarding through a GEM or another AI agent, feed it this README as the operational guide and ensure it honors the module/command table below.

## Features
- **Timestamped log streaming** – Every onboarding run saves output to `~/gft_onboarding_<date>_<time>.log` while still mirroring the stream to the console via `tee`, simplifying escalations to `#devops-support`.
- **OS-aware package resolution** – `install_with_package_manager` auto-detects `brew`, `apt`, `dnf`, `apk`, `pacman`, or `winget`, so dependencies such as `gh`, `yq`, and `shellcheck` remain idempotent across platforms.

## Dependencies (gcs-devops-standards paths)
The onboarding scripts dynamically read from the following authoritative files:

| Capability | gcs-devops-standards Path | Purpose |
| --- | --- | --- |
| Role-to-tooling data | `foundations/governance/GOV-004-role-tooling-matrix.md` | Supplies the YAML matrices used for tools, repositories, VS Code extensions, and environment variables per role.
| Version pinning | `tooling/ssot/.tool-versions-gft` | Provides canonical versions consumed by `get_ssot_tool_version`.
| Tool specifications | `domains/tooling/standards/tool-002-technical-tooling-specifications.md` | Validates packages/versions during post-onboarding checks.
| Git policies | `gcs-studio-handbook/02-knowledge-base-hub/...` (referenced by validators) | Used to confirm hooks, commit policies, and GitHub org access.

Ensure the workstation running these scripts can pull `https://github.com/GenCr-ft/gcs-devops-standards.git`.

## Role → repositories
The onboarding scripts pull repository requirements from the `roles[].repositories`, `roles[].inherits`, and `default_repositories` nodes that live inside `gcs-devops-standards/foundations/governance/GOV-004-role-tooling-matrix.md`. The following summary mirrors the mock matrix committed to this repository so contributors understand the inheritance model:

| Role / Scope | Source in matrix | Repositories cloned |
| --- | --- | --- |
| `default_repositories` | Top-level list | `gcs-devops-standards` |
| `common-base` | `roles[].name` | `gcs-studio-handbook` + inherits everything from `default_repositories` |
| `lead-developer-tech-lead` | `roles[].inherits: common-base` | `gct-service-template-py`, `gcs-plt-tools` |
| `devops-specialist` | `roles[].inherits: lead-developer-tech-lead` | `gencraft-iac` + inherited repos |

🛠 **Updating the matrix when a new repository becomes mandatory:**

1. Edit the markdown file inside `gcs-devops-standards` and add the repository to either `default_repositories` (if every persona needs it) or to the `repositories` array of the appropriate role.
2. Open a PR in `gcs-devops-standards` so GOV-004 reviewers can approve the change.
3. No code change is required in this repo—the Bash helper merges `default_repositories`, `common-base`, and the selected role automatically—but remember to update this README table if the mock data diverges from production SSoT values.

## Script Modules & Commands
| Module | Location | Primary SSoT Input | Primary Invocation |
| --- | --- | --- | --- |
| Main Orchestrator | `gft-onboarding.sh` | Role matrix + `.tool-versions-gft` | `./gft-onboarding.sh`
| Helper Library | `includes/01_helpers.sh` | Role matrix discovery utilities | Auto-sourced by orchestrator
| Installer Library | `includes/02_installers.sh` | `.tool-versions-gft` for version lookups | Auto-sourced; dispatch via `install_tools_for_role`
| Configuration Library | `includes/03_configuration.sh` | Role matrix for repos/env vars/extensions | Auto-sourced; run via functions `configure_*`
| Python role helpers | `includes/get_role_{tools,repos,env_vars}.py` | Role matrix YAML passed on stdin | Called by Bash libraries
| Windows bootstrapper | `onboarding-win.ps1` | Mirrors orchestrator behavior | `powershell -ExecutionPolicy Bypass -File onboarding-win.ps1`
| Validation (interactive) | `validate-environment.sh` | Role matrix + tool specs | `./validate-environment.sh`
| DevOps deep validation | `validate-gft-devops-environment.sh` | Tooling ADRs referenced inside script | `./validate-gft-devops-environment.sh`
| OpenTofu env helper | `setup-local-tofu-env.sh` | IaC backend standards | `. ./setup-local-tofu-env.sh`

Use this table when delegating tasks to other agents so they know which command to run for each module.

## Execution Flow
1. **Prerequisite scan** – `check_prerequisites` ensures `git`, `curl`, `yq`, and `python3` exist (installing via OS package manager if needed).
2. **SSoT sync** – `setup_ssot_repository` clones/updates the standards repo into `/tmp/gft-ssot-onboarding`.
3. **Role resolution** – `load_ssot_configuration` + `select_user_role` produce the YAML payload for the chosen persona.
4. **Tool installation** – `install_tools_for_role` enumerates SSoT-driven tools, installs binaries (Node via `nvm`, Python via `pyenv`, OpenTofu/GFT CLI via GitHub releases with checksums), and verifies Docker/AWS CLI.
5. **Configuration** – Git identity, SSH keys, VS Code extensions, environment variables, repo clones, and `gft config setup` are handled in order.
6. **Completion** – Operators receive a success banner plus instructions to restart shells/editors. Logs persist in the user’s home directory for audits.

## Platform-Specific Launch Procedures
### macOS & Linux (bash/zsh)
1. **Download with checksum verification**
   ```bash
   curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/gft-onboarding.sh -o gft-onboarding.sh
   curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/gft-onboarding.sh.sha256 -o gft-onboarding.sh.sha256
   sha256sum --check gft-onboarding.sh.sha256
   ```
   The checksum file is committed beside the script. Only continue if it returns `OK`.
2. **Execute**
   ```bash
   chmod +x gft-onboarding.sh
   ./gft-onboarding.sh
   ```
3. **Follow prompts** for role selection, sudo approvals, and SSH/GitHub automation.

### Windows 10/11 via WSL2
1. **Download & verify**
   ```powershell
   curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/onboarding-win.ps1 -o onboarding-win.ps1
   curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/onboarding-win.ps1.sha256 -o onboarding-win.ps1.sha256
   Get-FileHash onboarding-win.ps1 -Algorithm SHA256 | ForEach-Object { "$($_.Hash)  onboarding-win.ps1" } | \
     Select-String -Pattern (Get-Content onboarding-win.ps1.sha256)
   ```
   Ensure PowerShell reports a matching checksum.
2. **Run as Administrator**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   ./onboarding-win.ps1
   ```
   The script enables WSL2, installs Ubuntu if missing, copies `.env`, and launches the Bash orchestrator automatically.

## Diagnostics & Support
- **Environment validators**
  - `./validate-environment.sh` re-runs the role checks from the SSoT, counting pass/fail items.
  - `./validate-gft-devops-environment.sh` focuses on PROJ-103 DevOps tooling (Git, gh, OpenTofu, jq, linting stack) and versions.
- **`gft doctor`** – Once `gft-cli` is installed, `gft doctor` offers a CLI-native health report aligned with GOV-004; run it whenever validation scripts fail.
- **Debug environment variables**
  - `TEST_ENV=1 ./gft-onboarding.sh` skips confirmation prompts for automated testing.
  - Override `GFT_SSOT_REPO`/`GFT_SSOT_PATH` temporarily to test forks or offline caches.
- **Support channels**
  - Slack: `#devops-support` for real-time help.
  - Issue tracker: open tickets in `GenCr-ft/gcd-onboarding-scripts` with logs attached.
  - Include the log file (`~/gft_onboarding_<date>_<time>.log`) plus validator output in every escalation.

## Testing
| Scenario | Command | Notes |
| --- | --- | --- |
| Shell unit smoke | `TEST_ENV=1 ./gft-onboarding.sh` | Runs orchestration without confirmations; mock commands should be wrapped before CI.
| Role validation | `./validate-environment.sh` | Confirms installed tools/repos for a selected role.
| DevOps baseline | `./validate-gft-devops-environment.sh` | Ensures minimum versions for Git, gh, OpenTofu, jq, mdl, tflint, etc.
| Windows pipeline | `pwsh -File onboarding-win.ps1` | Use in CI to confirm WSL bootstrap behavior.

## Troubleshooting
| Symptom | Resolution |
| --- | --- |
| `Permission denied` running `gft-onboarding.sh` | Ensure the file is executable (`chmod +x gft-onboarding.sh`) and re-run under your user account.
| `yq: command not found` | Rerun the script; `check_prerequisites` installs it. If blocked, manually install (`brew install yq` or `sudo apt install yq`).
| Docker or gh auth failures | Run `docker info` / `gh auth login` manually, then re-run the onboarding script; these are prerequisites for repo cloning and CLI setup.
| Checksum mismatch | Delete the script, re-download both the script and `.sha256`, and verify network integrity before running anything.
| Script aborted with `log_error` or trap banner | Grab the latest `~/gft_onboarding_<date>_<time>.log` and send it to the DevOps guild via Slack `#devops-support` (or attach it to the GitHub issue) so they can replay the failing command sequence.

## Knowledge Base Discoverability
Add or update the KB entry **“How-To: Onboard devs”** to link to this README (`https://github.com/GenCr-ft/gcd-onboarding-scripts/blob/main/README.md`). Track the KB ticket ID inside your sprint board so the enablement guild can audit discoverability.

## Linked Documentation
Extended usage notes for auxiliary scripts (`onboarding-win.ps1`, `setup-local-tofu-env.sh`, `validate-*`) live in [`docs/auxiliary-scripts.md`](docs/auxiliary-scripts.md). Keep those sections in sync whenever script flags or parameters change.
