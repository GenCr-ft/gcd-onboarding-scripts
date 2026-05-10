---
docId: ENG-AGENT-009
title: Agent Guide for gcd-onboarding-scripts
lifecycle-stage: approved
knowledgeGuardian: Architecture Lead
---
# AGENTS.md — gcd-onboarding-scripts

## Project Overview

Cross-platform developer onboarding orchestration for GenCr@ft Studio. The main script (`gft-onboarding.sh`) is role-based and idempotent — it reads the role/tool matrix from `gcs-devops-standards`, clones the repos required for the selected role, installs tools, configures the environment, and runs post-install validators. A PowerShell entry point (`onboarding-win.ps1`) bootstraps Windows/WSL2 before delegating to the bash orchestrator.

## Prerequisites

- Bash 4+ (Linux/macOS) or WSL2 (Windows)
- Python 3.9+ (for YAML-parsing helpers in `includes/`)
- Internet access (or internal mirror) for tool downloads
- `gcs-devops-standards` must be accessible (pulled at runtime for role matrix and version pins)

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
- Branch naming: `feat/`, `fix/`, `docs/`, `chore/`.
- AI commits: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`

## Inter-repo Dependencies

| Dependency | Repo | How used |
|-----------|------|---------|
| Role/tool matrix | `gcs-devops-standards` | GOV-GUIDE-010 pulled at runtime for role → tool mapping |
| Version pinning | `gcs-devops-standards` | Tool version specs and ENV_VARIABLES_STANDARD |
| VS Code recommendations | `gcs-devops-standards` | Workspace config pulled during setup |

## Notes for Agents

- **Idempotency is critical** — every action must check system state before executing (never blindly re-install or overwrite).
- Role inheritance model: `default_repositories` → `common-base` → `specific-role`. Changes to this model require careful testing across all roles.
- Cross-platform support: shell detection (bash vs zsh vs PowerShell) must be maintained.
- When adding a new tool to the matrix, update `gcs-devops-standards` first; this script reads from that SSoT at runtime.
- Shell scripts must pass `shellcheck` without warnings.
- All Markdown files must carry valid SSoT YAML frontmatter.
