-----

title: GenCr@t Studio Onboarding Script Suite
status: Active
owners:
  - GCS DevOps Enablement Guild
last_reviewed: 2025-06-26

-----

# GenCr@t Studio Onboarding Script (`gft-onboarding.sh`)

## Overview

This suite serves as the approved Single Source of Truth (SSoT) for onboarding developers (human or AI) into GenCr@t Studio. It dynamically configures a standardized, compliant local development environment by consuming approved standards from the `gcs-devops-standards` repository.

### Key Principles

  * **SSoT-Driven:** Pulls standards exclusively from `gcs-devops-standards`.
  * **Role-Based:** Respects the role matrix; agents/users never install unsanctioned tooling.
  * **Idempotent:** Safe to re-run; checks system state before action.
  * **Transparent:** Streams output to console and saves detailed logs (`~/gft_onboarding_<date>_<time>.log`).
  * **Cross-Platform:** Supports macOS (zsh), Linux (bash/zsh), and Windows 10/11 (via WSL2/Ubuntu LTS).

## Architecture & Dependencies

The script relies on specific artifacts within `gcs-devops-standards`. The workstation must be able to pull `https://github.com/GenCr-ft/gcs-devops-standards.git`.

### SSoT Configuration Paths

| Capability | Path in `gcs-devops-standards` | Purpose |
| :--- | :--- | :--- |
| **Role/Tool Data** | `foundations/governance/GOV-004-role-tooling-matrix.md` | Matrix for tools, repos, VS Code extensions, and env vars. |
| **Version Pinning** | `tooling/ssot/.tool-versions-gft` | Canonical versions for `get_ssot_tool_version`. |
| **Tool Specs** | `domains/tooling/standards/tool-002-technical-tooling-specifications.md` | Validation of packages/versions. |
| **Env Vars** | `tooling/ENV_VARIABLES_STANDARD.md` | Common and role-specific exports. |
| **VS Code** | `tooling/VSCODE_RECOMMENDATIONS.md` | Global and role-targeted extension IDs. |
| **Docker** | `tooling/ssot/.docker-images-gft` | Manifest of container images to pre-pull. |

### Role Inheritance Model

Repositories are cloned based on the following inheritance logic defined in `GOV-004`:

1.  **`default_repositories`**: Top-level list (e.g., `gcs-devops-standards`).
2.  **`common-base`**: Inherits default; adds shared repos (e.g., `gcs-studio-handbook`).
3.  **Specific Role**: Inherits `common-base`; adds role-specific repos (e.g., `gct-service-template-py`, `gencraft-iac`).

### Script Modules

| Module | Script | Description |
| :--- | :--- | :--- |
| **Orchestrator** | `gft-onboarding.sh` | Main entry point. |
| **Libraries** | `includes/*.sh` | Helpers for discovery (`01`), installation (`02`), and config (`03`). |
| **Python Helpers** | `includes/get_role_*.py` | Parses YAML role matrices. |
| **Windows Bootstrapper** | `onboarding-win.ps1` | Enables WSL2, installs Ubuntu, launches orchestrator. |
| **Validators** | `validate-environment.sh` <br> `validate-gft-devops-environment.sh` | Validates role installs and DevOps tooling (PROJ-103). |
| **Tofu Helper** | `setup-local-tofu-env.sh` | Configures OpenTofu backend standards. |

## Prerequisites

1.  **Permissions:** `sudo` (macOS/Linux) or Administrator (Windows).
2.  **Connectivity:** Internet access for cloning and package downloads.
3.  **Accounts:** Active GenCr@t GitHub account (login required).
4.  **System Tools:** Script `check_prerequisites` auto-detects/installs `git`, `curl`, `yq`, and `python3`.

## Installation & Usage

### macOS & Linux

Run the following to download, verify checksums, and execute:

```bash
curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/gft-onboarding.sh -o gft-onboarding.sh
curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/gft-onboarding.sh.sha256 -o gft-onboarding.sh.sha256
sha256sum --check gft-onboarding.sh.sha256
chmod +x gft-onboarding.sh
./gft-onboarding.sh
```

### Windows (via WSL2)

Run via PowerShell as Administrator to verify checksums and bootstrap WSL2:

```powershell
curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/onboarding-win.ps1 -o onboarding-win.ps1
curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/onboarding-win.ps1.sha256 -o onboarding-win.ps1.sha256
Get-FileHash onboarding-win.ps1 -Algorithm SHA256 | ForEach-Object { "$($_.Hash)  onboarding-win.ps1" } | Select-String -Pattern (Get-Content onboarding-win.ps1.sha256)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\onboarding-win.ps1
```

*Note: The Windows script enables WSL2, installs Ubuntu if missing, copies `.env`, and automatically launches the bash orchestrator.*

## Execution Flow

1.  **Prerequisite Scan:** Checks/installs `git`, `curl`, `yq`, `python3` via OS package manager (`brew`, `apt`, `dnf`, etc.).
2.  **SSoT Sync:** Clones `gcs-devops-standards` to `/tmp/gft-ssot-onboarding`.
3.  **Role Selection:** Prompts user for role; loads configuration via `load_ssot_configuration`.
4.  **Installation:** Installs binaries (nvm, pyenv, OpenTofu, GFT CLI, etc.) and verifies Docker/AWS CLI.
5.  **Configuration:** Sets Git identity, SSH keys, VS Code extensions, Env Vars, clones repos, and runs `gft config setup`.
6.  **Validation:** Runs `pre-commit run --all-files` in the standards repo.

## Post-Installation & Validation

1.  **Restart:** Close/reopen terminals and restart VS Code.
2.  **Validation Scripts:**
      * Run `./validate-environment.sh` to verify role-specific tools/repos.
      * Run `./validate-gft-devops-environment.sh` for DevOps tooling baselines.
      * Run `gft doctor` for a CLI-native health report.
3.  **Manual Check:** Verify pre-commit hooks:
    ```bash
    cd "$GFT_PROJECTS_HOME/gcs-devops-standards" && pre-commit run --all-files
    ```

## Troubleshooting & Support

### Common Issues

| Symptom | Resolution |
| :--- | :--- |
| **Permission denied** | Ensure executable permissions (`chmod +x`) and run with appropriate user rights. |
| **Package fails** | Check internet; update package manager (`apt update`/`brew update`). |
| **Auth fails** | Run `gh auth login` or `docker info` manually. |
| **Checksum mismatch** | Re-download script and `.sha256` file. |

### Diagnostics

  * **Logs:** Check `~/gft_onboarding_<date>_<time>.log`.
  * **Testing:** Use `TEST_ENV=1 ./gft-onboarding.sh` to skip confirmation prompts (CI/testing).
  * **Support:** Contact `#devops-support` on Slack or open an issue in `GenCr-ft/gcd-onboarding-scripts` with logs attached.

### Documentation

  * **Auxiliary Scripts:** See [`docs/auxiliary-scripts.md`](https://www.google.com/search?q=docs/auxiliary-scripts.md) for details on `onboarding-win.ps1` and validators.
  * **Knowledge Base:** Link this README in the "How-To: Onboard devs" KB entry.