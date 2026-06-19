---
docId: ENG-READ-009
title: gcd-onboarding-scripts
version: 0.2.0
authors:
- GCS DevOps Enablement Guild
- AI Compliance Agent
reviewers: []
creation_date: '2025-06-26'
last_updated_date: '2026-06-19'
knowledgeGuardian:
- Béatrice (GCT-MGT-SPM-001)
language: en
summary: >
  Approved Single Source of Truth (SSoT) for onboarding developers into GenCr@ft Studio.
  Automates environment configuration via gcs-core-governance.
metadata:
  lifecycle-stage: approved
  keywords:
  - onboarding
  - dev-environment
  - automation
  - bash
  - ssot
  scope: project-platform
  domain: engineering
  doc-type: readme
  intended-audience:
  - contributors
  security-classification: l2_confidential
---
# GenCr@ft Studio Onboarding Script (`gft-onboarding.sh`)

## Overview

This suite serves as the approved Single Source of Truth (SSoT) for onboarding developers into GenCr@ft Studio. It dynamically configures a standardized, compliant local development environment by consuming approved standards from the `gcs-core-governance` repository.

## Start Here

`AGENTS.md` is the repo-local authority and the first read for agents.

`gft-onboarding.sh` is the primary first-run entry point. New contributors
should use the workspace quickstart path first, then read the repo-local
`AGENTS.md` for the project they clone.

```bash
git clone https://github.com/GenCr-ft/gcd-onboarding-scripts.git
cd gcd-onboarding-scripts
bash gft-onboarding.sh --quickstart --workspace aethel
```

Replace `aethel` with `evai-platform`, `agent-factory`, `workspace-ops`, or
`studio-gencraft` if that is your starting workspace.

`validate-environment.sh`, `validate-devops-environment.sh`, and
`setup-local-tofu-env.sh` are the main post-install validation surfaces.

`gcs-core-governance` is the runtime SSoT source for role/tool matrices,
version pins, and environment configuration. Treat copied output as derived, not
authoritative.

## Surface Map

| Surface | Role | Notes |
| --- | --- | --- |
| `AGENTS.md` | Repo authority | First read for any contributor or agent |
| `README.md` | Human-facing summary | Quick orientation only |
| `gft-onboarding.sh` | Onboarding orchestrator | First-run path |
| `onboarding-win.ps1` | Windows bootstrap | WSL2 / Windows delegation |
| `validate-environment.sh` | Validator | Post-install validation |
| `validate-devops-environment.sh` | Validator | DevOps baseline validation |
| `setup-local-tofu-env.sh` | Helper | OpenTofu environment setup |
| `includes/` | Helpers | Role discovery, install, and config modules |
| `docs/` | Support docs | Reference material and auxiliary notes |
| `spec/` | Specs | Behavioural and operational specs |
| `tests/` | Test fixtures | Validation inputs and regression coverage |

## Command Matrix

| Task | Command | Result |
| --- | --- | --- |
| New contributor quickstart | `bash gft-onboarding.sh --quickstart --workspace <workspace>` | Non-interactive setup for one bounded workspace |
| Run onboarding | `bash gft-onboarding.sh [--role <role-name>]` | Installs and configures the local environment |
| Validate environment | `bash validate-environment.sh` | Checks installed tools against the selected role |
| Validate DevOps baseline | `bash validate-devops-environment.sh` | Checks DevOps tooling prerequisites |
| Configure local OpenTofu | `bash setup-local-tofu-env.sh` | Prepares local OpenTofu variables |
| Run tests | `bash test.sh` | Executes the repo test suite |

### Workspaces

| Workspace | Start here when you want to contribute to |
| --- | --- |
| `aethel` | Game client, server, PCG, auth, persistence, and Aethel backlog work |
| `evai-platform` | EvolvAI DevSphere CLI, platform services, and platform architecture |
| `agent-factory` | Gem operations, agent blueprints, skills, prompts, and automation |
| `workspace-ops` | CI, onboarding, governance linters, shared actions, and infrastructure |
| `studio-gencraft` | Studio governance, handbook, legal, security, project management, and public website |

## Generated / No-Edit Surfaces

- Logs under `~/gft_onboarding_<date>_<time>.log` are generated output.
- Role/tool data is read from `gcs-core-governance` at runtime; do not treat
  copied data as a source of truth.
- Installation output and cached environment state are derived artifacts, not
  active authoring surfaces.

### Key Principles

- **SSoT-Driven:** Pulls standards exclusively from `gcs-core-governance`.
- **Role-Based:** Respects the role matrix; agents/users never install unsanctioned tooling.
- **Idempotent:** Safe to re-run; checks system state before action.
- **Transparent:** Streams output to console and saves detailed logs (`~/gft_onboarding_<date>_<time>.log`).
- **Cross-Platform:** Supports macOS (zsh), Linux (bash/zsh), and Windows 10/11 (via WSL2/Ubuntu LTS).

## Architecture & Dependencies

The script pulls its role/tool matrix from `gcs-core-governance` at runtime, resolves a 3-tier inheritance chain (`default_repositories` → `common-base` → specific role), and configures the machine to match. The workstation must be able to pull `https://github.com/GenCr-ft/gcs-core-governance.git`.

See [AGENTS.md](./AGENTS.md) for the full SSoT configuration paths, module descriptions, and role inheritance model.

## Prerequisites

1. **Permissions:** `sudo` (macOS/Linux) or Administrator (Windows).
2. **Connectivity:** Internet access for cloning and package downloads.
3. **Accounts:** Active GenCr@ft GitHub account (login required).
4. **System Tools:** Script `check_prerequisites` auto-detects/installs `git`, `curl`, `yq`, and `python3`.

## Installation & Usage

### macOS & Linux

```bash
git clone https://github.com/GenCr-ft/gcd-onboarding-scripts.git
cd gcd-onboarding-scripts
bash gft-onboarding.sh --quickstart --workspace aethel
```

### Windows (via WSL2)

Run via PowerShell as Administrator to bootstrap WSL2:

```powershell
git clone https://github.com/GenCr-ft/gcd-onboarding-scripts.git
cd gcd-onboarding-scripts
.\onboarding-win.ps1 -Quickstart -Workspace aethel
```

*Note: The Windows script enables WSL2, installs Ubuntu if missing, copies `.env`, and automatically launches the bash orchestrator.*

## Execution Flow

1. **Prerequisite Scan:** Checks/installs `git`, `curl`, `yq`, `python3` via OS package manager (`brew`, `apt`, `dnf`, etc.).
2. **SSoT Sync:** Clones `gcs-core-governance` to `/tmp/gft-ssot-onboarding`.
3. **Role Selection:** Prompts user for role; loads configuration via `load_ssot_configuration`.
4. **Installation:** Installs binaries (nvm, pyenv, OpenTofu, GFT CLI, etc.) and verifies Docker/AWS CLI. `gft` itself is delegated to the cloned `gcs-plt-tools/onboard.sh` flow once the workspace exists, so there is one canonical owner for the global wrapper contract.
5. **Configuration:** Sets Git identity, SSH keys, VS Code extensions, Env Vars, clones repos, and runs `gft config setup`.
6. **Validation:** Runs `pre-commit run --all-files` in the standards repo.

## Post-Installation & Validation

1. **Restart:** Close/reopen terminals and restart VS Code.
2. **Validation Scripts:**
   - Run `./validate-environment.sh` to verify role-specific tools/repos.
   - Run `./validate-devops-environment.sh` for DevOps tooling baselines.
   - Run `gft doctor` for a CLI-native health report.
3. **Manual Check:** Verify pre-commit hooks:

    ```bash
    cd "$GFT_PROJECTS_HOME/gcs-core-governance" && pre-commit run --all-files
    ```

## Development & Testing

Contributors working on this repo can run the test suite without going through the full onboarding flow:

```bash
bash test.sh   # discovers and runs all tests/test_*.sh files
```

There is no `onboard.sh` in this repo — it *is* the onboarding system.

## Troubleshooting & Support

### Common Issues

| Symptom | Resolution |
| :--- | :--- |
| **Permission denied** | Ensure executable permissions (`chmod +x`) and run with appropriate user rights. |
| **Package fails** | Check internet; update package manager (`apt update`/`brew update`). |
| **Auth fails** | Run `gh auth login` or `docker info` manually. |
| **Download fails** | Confirm GitHub access and network connectivity, then re-run the download command. |

### Diagnostics

- **Logs:** Check `~/gft_onboarding_<date>_<time>.log`.
- **Testing:** Use `TEST_ENV=1 ./gft-onboarding.sh` to skip confirmation prompts (CI/testing).
- **Support:** Contact `#devops-support` on Slack or open an issue in `GenCr-ft/gcd-onboarding-scripts` with logs attached.

### Documentation

- **Auxiliary Scripts:** See `docs/auxiliary-scripts.md` for details on `onboarding-win.ps1` and validators.
- **Knowledge Base:** Link this README in the "How-To: Onboard devs" KB entry.

---

*For technical architecture and agent-specific guidance, see [AGENTS.md](./AGENTS.md).*
