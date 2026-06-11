# AGENTS.md — gcd-onboarding-scripts

## Project Overview

Cross-platform developer onboarding orchestration for GenCr@ft Studio. The main script (`gft-onboarding.sh`) is role-based and idempotent — it reads the role/tool matrix from `gcs-core-governance`, clones the repos required for the selected role, installs tools, configures the environment, and runs post-install validators. A PowerShell entry point (`onboarding-win.ps1`) bootstraps Windows/WSL2 before delegating to the bash orchestrator.

## Prerequisites

- Bash 4+ (Linux/macOS) or WSL2 (Windows)
- Python 3.9+ (for YAML-parsing helpers in `includes/`)
- Internet access (or internal mirror) for tool downloads
- `gcs-core-governance` must be accessible (pulled at runtime for role matrix and version pins)

## Quick Commands

| Task | Command |
|------|---------|
| Run unit tests | `bash test.sh` |
| Run onboarding (Linux/macOS) | `bash gft-onboarding.sh [--role <role-name>]` |
| Validate environment | `bash validate-environment.sh` |
| Validate DevOps env | `bash validate-devops-environment.sh` |
| Configure OpenTofu env | `bash setup-local-tofu-env.sh` |

## Usage

```bash
# Linux/macOS:
bash gft-onboarding.sh [--role <role-name>]

# Windows (PowerShell, runs as Administrator):
.\onboarding-win.ps1   # enables WSL2, then delegates to bash orchestrator

# Post-install validators:
bash validate-environment.sh            # checks installed tools against role requirements
bash validate-devops-environment.sh     # checks DevOps-specific tools (OpenTofu, Docker, etc.)
bash setup-local-tofu-env.sh            # configures local OpenTofu environment variables
```

## Architecture & Key Directories

```
gcd-onboarding-scripts/
  gft-onboarding.sh           — Main orchestrator (role-based, idempotent)
  onboarding-win.ps1          — Windows bootstrap (enables WSL2, launches bash)
  validate-environment.sh     — Post-install validator
  validate-devops-environment.sh — DevOps-specific validator
  setup-local-tofu-env.sh     — OpenTofu env configuration
  includes/                   — Shell modules for discovery, installation, configuration
    get_role_*.py              — Python helpers for YAML role matrix parsing
  docs/                       — Auxiliary documentation
  spec/                       — Specification files
  tests/                      — Test fixtures
```

## Linting & Formatting

```bash
pre-commit run --all-files   # shellcheck (shell scripts), markdownlint, yamllint, commitlint
```

## Commit & PR Conventions

- Conventional Commits v1.0.0.
- Branch: Conforms strictly to `feat/issue-ID-slug` and `fix/issue-ID-slug` branch naming standard (e.g., `feat/issue-104-inventory-service`).
- Co-author trailer: Strictly prohibited in this workspace due to administrative blocks. Do NOT write or push commits containing the `Co-Authored-By` trailer.

## Inter-repo Dependencies

| Dependency | Repo | How used |
|-----------|------|---------|
| Role/tool matrix | `gcs-core-governance` | GOV-GUIDE-010 pulled at runtime for role → tool mapping |
| Version pinning | `gcs-core-governance` | Tool version specs and ENV_VARIABLES_STANDARD |
| VS Code recommendations | `gcs-core-governance` | Workspace config pulled during setup |

## SSoT Configuration Paths

All role/tool data is read at runtime from `gcs-core-governance` (cloned to `/tmp/gft-ssot-onboarding`). The relevant paths are:

| Capability | Path in `gcs-core-governance` | Purpose |
| :--- | :--- | :--- |
| **Role/Tool Data** | `foundations/governance/GOV-GUIDE-010.role-tooling--resource-matrix.md` | Matrix for tools, repos, VS Code extensions, and env vars. |
| **Version Pinning** | `tooling/ssot/.tool-versions-gft` | Canonical versions for `get_ssot_tool_version`. |
| **Tool Specs** | `domains/tooling/standards/tool-002-technical-tooling-specifications.md` | Validation of packages/versions. |
| **Env Vars** | `tooling/ENV_VARIABLES_STANDARD.md` | Common and role-specific exports. |
| **VS Code** | `tooling/VSCODE_RECOMMENDATIONS.md` | Global and role-targeted extension IDs. |
| **Docker** | `tooling/ssot/.docker-images-gft` | Manifest of container images to pre-pull. |

## Script Modules

| Module | Script | Description |
| :--- | :--- | :--- |
| **Orchestrator** | `gft-onboarding.sh` | Main entry point — coordinates the full flow. |
| **Libraries** | `includes/*.sh` | Helpers for discovery (`01`), installation (`02`), and config (`03`). |
| **Python Helpers** | `includes/get_role_*.py` | Parses YAML role matrices (no external deps — uses `simple_yaml.py`). |
| **Windows Bootstrapper** | `onboarding-win.ps1` | Enables WSL2, installs Ubuntu, delegates to bash orchestrator. |
| **Validators** | `validate-environment.sh`, `validate-devops-environment.sh` | Post-install validation of role installs and DevOps tooling. |
| **Tofu Helper** | `setup-local-tofu-env.sh` | Configures OpenTofu backend environment variables. |

## Role Inheritance Model

Repositories and tools are resolved via a 3-tier inheritance chain defined in `GOV-004-role-tooling-matrix.md`:

1. **`default_repositories`** — top-level list cloned for every role (e.g., `gcs-core-governance`).
2. **`common-base`** — inherits `default_repositories`; adds shared repos (e.g., `gcs-core-governance`).
3. **Specific role** — inherits `common-base`; adds role-specific repos (e.g., `gct-service-template-py`, `gencraft-iac`).

Changes to this model require updating `gcs-core-governance` first and testing across all roles.

## Execution Flow

1. **Prerequisite Scan** — checks and installs `git`, `curl`, `yq`, `python3`, `unzip` via OS package manager (`brew`, `apt`, `dnf`, etc.).
2. **SSoT Sync** — clones `gcs-core-governance` to `/tmp/gft-ssot-onboarding`.
3. **Role Selection** — prompts for role; loads configuration via `load_ssot_configuration` (calls Python helpers).
4. **Installation** — installs binaries (nvm, pyenv, OpenTofu, GFT CLI, etc.) and verifies Docker/AWS CLI.
5. **Configuration** — sets Git identity, SSH keys, VS Code extensions, env vars, clones repos, runs `gft config setup`.
6. **Validation** — runs `pre-commit run --all-files` in the standards repo.

## Key Patterns

- **Adding a new tool**: update `gcs-core-governance` first — never hardcode tool versions or paths in this repo; everything is read from SSoT at runtime.
- **Cross-platform shell detection** lives in `includes/01_helpers.sh`; adding a new platform requires changes there.
- **`TEST_ENV=1`** skips confirmation prompts — always set in CI runs and unit tests.
- **Testing against the SSoT locally**: unit tests use mock fixtures in `tests/fixtures/mock_ssot/`; do not let tests reach the real `gcs-core-governance`.

## Notes for Agents

- **Idempotency is critical** — every action must check system state before executing (never blindly re-install or overwrite).
- Cross-platform support: shell detection (bash vs zsh vs PowerShell) must be maintained.
- When adding a new tool to the matrix, update `gcs-core-governance` first; this script reads from that SSoT at runtime.
- Shell scripts must pass `shellcheck` without warnings.
- All Markdown files must carry valid SSoT YAML frontmatter.
