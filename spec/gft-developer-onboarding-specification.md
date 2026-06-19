---
docId: G@FT.ai Developer Onboarding Script & Tooling Standardization
title: "Final AI Specification: G@FT.ai Developer Onboarding Script & Tooling Standardization"
version: 1.7
date: '2025-06-24'
recipient: "Code-Generating AI (Large Language Model - LLM)"
objective: "To provide comprehensive and detailed specifications for the AI-driven creation of a multi-platform (Bash) developer onboarding script, and to define the conceptual infrastructure of standardized GitHub repository templates for the G@FT.ai Studio."
---

# Final AI Specification: <G@FT.ai> Developer Onboarding Script & Tooling Standardization

---

## 1. Vision and General Objectives

### 1.1. Vision

The ambition is to streamline and standardize the technical integration of new <G@FT.ai> team members. A single, interactive onboarding script must enable any new developer to configure their local development environment completely, securely, and in alignment with studio standards, within a minimal timeframe. Concurrently, the creation of new GitHub repositories within the GenCr-ft organization must be facilitated by robust templates, ensuring immediate compliance with established standards.

### 1.2. Key Objectives for the Onboarding Script (Primary AI Deliverable)

* **Automated Tooling Installation:** Install and configure fundamental development tools to specific versions defined in a Single Source of Truth (SSoT).
* **Studio Tooling Installation:** Install internal <G@FT.ai> command-line tools, such as `gft-cli`.
* **Standardized Git Configuration:** Configure the user's Git identity, essential global settings, and guide them through secure SSH key setup for GitHub.
* **Local Standards Enforcement:** Implement and activate studio-standard Git Hooks, particularly for validating commit messages against Conventional Commits.
* **Shell Environment Configuration:** Persistently define common, non-sensitive studio environment variables.
* **IDE Standardization:** Propose and apply a recommended baseline VS Code configuration, including key extensions and settings.
* **Initial Resource Access:** Automatically clone essential <G@FT.ai> Studio GitHub repositories.
* **Performance Optimization:** Pre-load common development assets like Docker images to accelerate initial project startup.
* **Optimal User Experience:** The script must be interactive, clear in its instructions, idempotent (re-runnable without side-effects), and provide a ready-to-commit environment where all local tooling (e.g., SSoT linters and pre-commit hook dependencies) is functional immediately after completion.

### 1.3. Key Objectives for GitHub Repository Templates (Contextual Specification)

(Note to AI: The provisioning of these repository templates is handled via Infrastructure as Code (IaC) by the DevOps team (Gem A). Your role is to understand their expected contents to ensure the onboarding script and any generated file content are fully aligned.)

* **Structural Consistency:** Provide a standard baseline file and directory structure.
* **Built-in Quality & Standards:** Include base configurations for linters, formatters, and project-local Git Hooks.
* **CI/CD Ready:** Integrate a basic GitHub Actions workflow file that calls the studio's standard reusable CI workflows.
* **Legal and Organizational Compliance:** Include standard `LICENSE`, `README.md`, `CONTRIBUTING.md`, `.editorconfig`, and `CODE_OF_CONDUCT.md` files.

### 1.4. Central Single Source of Truth (SSoT)

The SSoT for all DevOps and development standards is the `GenCr-ft/gcs-core-governance` repository.
All configurations, scripts, template contents, and tool versions generated **MUST** be rigorously aligned with the standards and files documented within this repository. The onboarding script must explicitly reference it.

**Key SSoT Files to be Used by the Script:**

* `tooling/ssot/.tool-versions-gft`: A central file defining target versions for all key tools (e.g., `nodejs 20.18.0`, `python 3.11.5`, `opentofu 1.6.0`).
* `tooling/ssot/.docker-images-gft`: A text file listing common Docker images to pre-pull.
* `documentation/governance/GOV-POLI-001.role-tooling--resource-matrix.md`: (NEW) A document mapping studio roles to the tools they require. The onboarding script should use this to determine which dependencies to install for a given user.
* `tooling/templates/.editorconfig_standard`: The studio's base `.editorconfig` file.
* `tooling/git-hooks/commitlint.config.js`: The standard configuration for `commitlint`.
* `tooling/ENG-STAN-002.environment-variable-standard.md`: The definition of common environment variables.
* `tooling/ENG-STAN-003.vs-code-extension-recommendations.md`: The list of recommended VS Code extensions and base `settings.json`.

### 1.5. Key Characteristics of `gft-cli` (Contextual Specification)

(This describes the expected behavior of the internal tool being installed by the onboarding script.)

* **Configuration Management:** Provides commands to manage local configurations (`gft config setup`).
* **Developer Assistance:** Offers utilities to assist and control contributor workflows.
* **Self-Update Mechanism:** The CLI **MUST** automatically check for new versions and prompt for updates.
* **Environment Diagnostics:** The CLI **MUST** provide a `doctor` command (`gft doctor`) to analyze the local environment against studio standards and report misconfigurations.

---

## 2. Detailed Specifications for the Onboarding Script (Bash)

The script must be developed in Bash for compatibility with target environments: Linux (Ubuntu 22.04+ LTS), macOS (latest two major versions), and Windows 10/11 via WSL2 (using an Ubuntu LTS distribution).

### 2.1. General Script Characteristics

* **Modularity:** Structure the script into well-defined functions.
* **Idempotency:** Each function must verify if a tool or setting is already correctly configured.
* **Interactivity & UX:** Use clear `echo` statements and `read -p` prompts.
* **Logging:** Redirect detailed stdout/stderr to a timestamped log file.
* **Error Handling:** Use `set -e`, `set -o pipefail`, and `trap`.
* **Dependency Checks:** The script must verify it has the basic commands it needs to run.

### 2.2. Main Orchestration Module

* Display a welcome message.
* Detect and confirm the OS.
* Fetch SSoT files: Download or clone `GenCr-ft/gcs-core-governance` to a temporary location to read `.tool-versions-gft`, `.docker-images-gft`, the role-tooling matrix, and other configs.
* **Determine User Role:** Interactively ask the user for their primary role (e.g., `devops-specialist`, `lead-developer-tech-lead`).
* Execute other modules sequentially, passing the user's role and SSoT info.
* Execute Final Configuration & Validation Module.
* Execute Performance & Caching Module.
* Conclude with a summary of actions, remaining manual steps, and useful links.

### 2.3. Tool Installation Module

(For each tool, the script must first check if it is required for the user's role based on the role-tooling-matrix, then install the specific version defined in `.tool-versions-gft`.)

#### 2.3.1. Git (Target: >= 2.30+)

Verify version and install/upgrade.

#### 2.3.2. NVM (Node Version Manager)

Install and configure shell profile.

#### 2.3.3. Node.js & PNPM

Use `nvm` to install target Node.js. Use `npm` to install target `pnpm` (version pin in `.tool-versions-gft`; dispatcher case tracked in gcs-core-governance#56).

#### 2.3.4. Pyenv

Install and configure. Install Python build dependencies.

#### 2.3.5. Python & Poetry

Use `pyenv` to install target Python. Install target Poetry.

#### 2.3.6. `gft-cli` (Studio Tool)

* Version is managed by `gcs-plt-tools/onboard.sh`; it is **not** pinned in `.tool-versions-gft`. The `install_gft_cli()` function delegates entirely to that script.
* Verify installation with `gft version`.

#### 2.3.7. Core Pre-Commit Dependencies (NEW)

* **OpenTofu:** If required by role, download the specified version's binary from the official OpenTofu releases, verify its checksum, and install to the PATH. Verify with `tofu --version`.
* **ShellCheck:** If required by role, install via the system package manager (`sudo apt install shellcheck`, `brew install shellcheck`). Verify with `shellcheck --version`.
* **Commitlint:** If required by role, install via `pnpm i -g @commitlint/cli @commitlint/config-conventional`. Verify with `commitlint --version`.

#### 2.3.8. VS Code (Verification)

Check for `code` CLI in PATH.

#### 2.3.9. Docker (Verification)

Check for `docker` command and running daemon.

#### 2.3.10. AWS CLI v2 (Installation)

Install and guide user through secure configuration.

### 2.4. Git User Configuration Module

* Prompt for `user.name` and `user.email`.
* Execute `git config --global` for `user.name`, `user.email`, `init.defaultBranch main`, `core.editor "code --wait"`, `pull.rebase false`, `help.autocorrect true`, and `core.hooksPath ~/.gft-git-hooks`.

### 2.5. GitHub SSH Configuration Module

Check for `~/.ssh/id_ed25519`. If missing, guide user through generation, adding to `ssh-agent`, and adding the public key to their GitHub account. Test with `ssh -T git@github.com`.

### 2.6. Studio Git Hooks Setup Module

* Create the global hooks directory: `mkdir -p ~/.gft-git-hooks`.
* **`commit-msg` Hook:**
  * Create an executable `~/.gft-git-hooks/commit-msg` script that runs `commitlint` (note: the tool itself is installed in section 2.3.7).
  * The script must copy `GenCr-ft/gcs-core-governance/tooling/git-hooks/commitlint.config.js` to `~/.gft-git-hooks/`.
* **`pre-commit` Hooks (Tooling Setup):**
  * Install global managers: `pnpm add -g lint-staged` and `pip install pre-commit`.
  * Inform user that these are activated by project-level configurations.

### 2.7. Environment Variables Module

* Reference `GenCr-ft/gcs-core-governance/tooling/ENG-STAN-002.environment-variable-standard.md`.
* For each variable, check and append to the correct shell profile file if not already present.
* Create the `$GFT_PROJECTS_HOME` directory.

### 2.8. VS Code Configuration Module

* Reference `GenCr-ft/gcs-core-governance/tooling/ENG-STAN-003.vs-code-extension-recommendations.md`.
* Install recommended extensions and prompt user to merge `settings.json`.

### 2.9. Repository Cloning Module

* Use the `$GFT_PROJECTS_HOME` path.
* Interactively determine which repositories to clone based on user role. Always clone `gcs-core-governance`.
* Use `git clone git@github.com:GenCr-ft/REPO_NAME.git "$GFT_PROJECTS_HOME/REPO_NAME"`.

### 2.10. Final Configuration & Validation Module

**Objective:** Ensure studio-specific tooling is correctly configured.

#### 2.10.1. Execute `gft-cli` Configuration Setup

* Run the command `gft config setup`.
* Expected `gft-cli` behavior: Interactively prompt for the local path to `gcs-core-governance` and create `~/.gft/config.yaml`.

#### 2.10.2. Validate Environment Readiness

* Example Validation Step:
  * `cd "$GFT_PROJECTS_HOME/gcs-core-governance"`.
  * Run `pre-commit run --all-files` to test SSoT linters.
  * Check exit code for configuration errors.
  * `cd -`.

### 2.11. Performance & Caching Module

**Objective:** Accelerate the developer's first project startup by pre-caching common assets.

#### 2.11.1. Pre-load Common Docker Images

* Ask for user confirmation.
* Read the list of images from the SSoT file (`tooling/ssot/.docker-images-gft`).
* Loop through the list and execute `docker pull <image_name>` for each.

---

## 3. Specifications for GitHub Repository Templates (for IaC Context)

This section specifies the expected content of repository templates. The source for all standard files is the `GenCr-ft/gcs-core-governance` repository.

### 3.1. Files Common to All Templates

* `.github/` directory: `ISSUE_TEMPLATE/` and `pull_request_template.md`.
* `.editorconfig`: Copy of the studio standard file.
* `.gitignore`: Base template plus language-specific entries.
* `LICENSE`: Studio standard license file.
* `README.md`: Structured template linking to `gcs-core-governance`.
* `CONTRIBUTING.md` & `CODE_OF_CONDUCT.md`: Linking to standard versions.

### 3.2. Specific Additions per Template Type

* **Template: TypeScript/Node.js Service:**
  * `package.json` with scripts and standard `devDependencies`.
  * Configuration files (`.eslintrc.js`, etc.) using base configs from `gcs-core-governance/tooling/configs/`.
  * Husky configuration for `pre-commit` and `commit-msg`.
  * `.github/workflows/ci-ts.yml` calling the reusable CI workflow.
* **Template: Python/Poetry Application:**
  * `pyproject.toml` configured for Poetry, `ruff`, `mypy`, `pytest`.
  * `.pre-commit-config.yaml` with hooks for `ruff`, `mypy`, etc.
  * `.github/workflows/ci-py.yml` calling the reusable CI workflow.
(Similar detailed specifications should be followed for C#/.NET, Go, Rust templates as required.)

---

## 4. Documentation and Maintenance

* **Script Documentation:** A comprehensive `README.md` in the script's repository (e.g., `GenCr-ft/gft-onboarding-script`).
* **Template Documentation:** Documented in `GenCr-ft/gcs-core-governance/repository-templates/README.md`.
* **Evolution:** All artifacts are living documents and must be updated via Pull Requests and formal reviews.

---

This specification provides a comprehensive and actionable framework for an AI to generate the required scripts and configuration files, ensuring a standardized, efficient, and high-quality development ecosystem for <G@FT.ai> Studio.
