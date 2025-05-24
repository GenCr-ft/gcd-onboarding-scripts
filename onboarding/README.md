# <G@FT.ai> Developer Onboarding Scripts

This directory contains scripts to help new <G@FT.ai> studio members set up their local development environment quickly and consistently.

## Scripts

1. **`setup_gftai_windows_env.ps1`** (Current Target Version: `v1.0.13` or later)
    * **Purpose:** PowerShell script for **Windows users** to prepare the system for WSL2 and then launch the main Bash onboarding script.
    * **Functionality:**
        * Checks/guides WSL2 & required Windows features setup.
        * Checks/guides installation of a Linux distribution for WSL2 (e.g., Ubuntu).
        * Checks/guides installation of VS Code & 'Remote - WSL' extension.
        * Checks/guides installation of Docker Desktop (recommending WSL2 backend).
        * Copies a local `.env` file (if present) into WSL2 for the Bash script.
        * Launches `gftai_onboarding.sh` within WSL2.
    * **Usage:** Run as **Administrator** in PowerShell. Requires `gftai_onboarding.sh` in the same directory.

2. **`gftai_onboarding.sh`** (Current Target Version: `v1.1.2` or later)
    * **Purpose:** Main Bash script for **Linux, macOS, and Windows (via WSL2)** users for general development environment setup.
    * **Functionality:**
        * Loads configuration from `.env` file.
        * Installs/verifies core tools (Git, NVM/Node.js LTS, Python 3/pip).
        * Configures Git `user.name`/`user.email` locally per cloned repository.
        * Guides SSH key setup for GitHub.
        * Clones standard <G@FT.ai> studio repositories.
        * Creates a VS Code `.code-workspace` file.
        * Installs common recommended VS Code extensions.
        * Attempts to open VS Code in the new workspace.
    * **Usage:** Run directly in Bash (Linux/macOS) or is launched by `setup_gftai_windows_env.ps1` in WSL2.

3. **`gftai_devops_onboarding_addon.sh`** (Current Target Version: `v1.2.2` or later)
    * **Purpose:** **Additional** Bash script for **DevOps team members**. Run *after* `gftai_onboarding.sh`.
    * **Functionality:**
        * Loads configuration from a separate `.env.devops` file.
        * Installs/verifies DevOps-specific tools: OpenTofu, AWS CLI v2 (in a dedicated Python venv), `jq`, `yq`.
        * Creates a dedicated Python virtual environment for DevOps tools.
        * Guides through `aws configure`.
        * Installs additional VS Code extensions relevant to DevOps.
    * **Usage:** Run in Bash (Linux/macOS/WSL2) after the main onboarding. Can be customized with `.env.devops`.

4. **`.env.example`**
    * **Purpose:** An example configuration file for `gftai_onboarding.sh`.
    * **Usage:** Copy to `.env` and customize.

5. **`.env.devops.example`**
    * **Purpose:** An example configuration file for `gftai_devops_onboarding_addon.sh`.
    * **Usage:** Copy to `.env.devops` and customize for DevOps-specific settings.

## Full Documentation

For detailed instructions on how to use these scripts, prerequisites, troubleshooting, and `.env` file configuration, please refer to the **[G@FT.ai Developer Onboarding Guide](https://github.com/GenCr-ft/devops-standards/blob/main/guides/developer-onboarding.md)** (Note: Please ensure this link points to the correct final URL of `developer-onboarding.md` in the `devops-standards` repository once it's merged and finalized).

## Contribution

These scripts are maintained by Gem BB (Automation @ Camille). Please raise an issue in the `gencraft-devops-automation` repository for any bugs or feature requests.
