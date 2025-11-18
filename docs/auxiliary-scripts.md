# Auxiliary Script Reference

This document supplements the main README by detailing helper scripts that support onboarding, diagnostics, and infrastructure workflows.

## onboarding-win.ps1 (Windows bootstrapper)
- **Purpose**: Enables WSL2, validates VS Code/Docker Desktop, copies `.env`, and launches the Bash orchestrator for Windows engineers.
- **Invocation**:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  ./onboarding-win.ps1
  ```
- **Key behaviors**:
  - Calls `Ensure-WSLFeatures`, `Check-And-Install-WSLDistro`, and `Launch-BashOnboardingScript` (Section 6) to automatically run `gft-onboarding.sh` inside Ubuntu.
  - Prompts administrators when a restart is required after enabling WSL/VM features.
  - Copies `.env` from the PowerShell folder into the target WSL home directory to keep secrets aligned with Bash execution.
- **Logs & troubleshooting**: All major sections echo `[INFO]/[WARN]/[ERROR]` messages to the console. Capture transcripts with `Start-Transcript` for escalations.

## setup-local-tofu-env.sh (OpenTofu environment helper)
- **Purpose**: Sets AWS regions and prompts for `TF_VAR_github_token` so DevOps members can run OpenTofu plans locally against `github-org` infrastructure.
- **Usage**:
  ```bash
  source ./setup-local-tofu-env.sh
  ```
  Sourcing is mandatory so exported variables persist in the caller shell.
- **What it sets**:
  - `AWS_REGION` / `AWS_DEFAULT_REGION` (`eu-west-3` by default).
  - `TF_VAR_github_token` (prompted securely if absent).
  - Optional commented blocks exist for selecting `AWS_PROFILE` or direct key input; uncomment only if policy permits.
- **Next steps**: After sourcing, `cd` into your desired OpenTofu workspace (e.g., `environments/github-org`) before running `tofu init/plan`.

## validate-environment.sh (role-aware validator)
- **Purpose**: Confirms that a workstation still matches GOV-004 requirements for a selected role.
- **Execution**:
  ```bash
  chmod +x validate-environment.sh
  ./validate-environment.sh
  ```
- **Flow**:
  1. Syncs `gcs-devops-standards` into `/tmp/gft-ssot-validation`.
  2. Extracts YAML from `GOV-004-role-tooling-matrix.md` and `tool-002-technical-tooling-specifications.md`.
  3. Prompts for the role, then validates tools (`validate_tool`), repositories, and Git config.
  4. Prints pass/fail counts; success is zero failures.
- **Automation tips**: Run nightly on CI by seeding `ROLE_MATRIX_YAML` via the script or piping a predetermined selection into the `select` prompt.

## validate-gft-devops-environment.sh (PROJ-103 baseline)
- **Purpose**: Deep-dive check for DevOps/SRE contributors focusing on Git, gh, OpenTofu, jq, mdl, tflint, Docker, and hooks, referencing relevant ADRs.
- **Execution**:
  ```bash
  chmod +x validate-gft-devops-environment.sh
  ./validate-gft-devops-environment.sh
  ```
- **Highlights**:
  - Defines minimum major/minor versions (Git ≥2.x, gh ≥2.x, OpenTofu ≥1.6, etc.).
  - Provides OS-specific install suggestions if a command is missing.
  - Verifies Git global identity and `gh auth status` against the `GenCr-ft` org.
  - Counts failures/warnings so teams can gate pull requests.
- **When to run**: Before committing IaC or automation to PROJ-103 or whenever `gft doctor` surfaces CLI issues.

## Diagnostic entry points in docs
When writing KB or runbook content, reference this file directly so that Windows/DevOps/IaC specialists can self-serve without searching through the repository tree.
