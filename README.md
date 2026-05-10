# GenCr@ft Studio — Onboarding Scripts

Automated environment setup and validation for GenCr@ft Studio developers.

## Overview

This repository provides a standardized, role-based onboarding suite that configures a compliant local development environment. It ensures that every contributor (human or AI) has the correct tools, versions, and repository access required for their specific role.

### Key Features

- **SSoT-Driven**: Pulls configuration directly from `gcs-devops-standards`.
- **Idempotent**: Safe to re-run; checks system state before making changes.
- **Cross-Platform**: Supports macOS, Linux (Bash/Zsh), and Windows (via WSL2).

## Getting Started

### Prerequisites

- Internet connectivity and a GitHub account.
- `sudo` (macOS/Linux) or Administrator (Windows) permissions.

### Installation

#### macOS & Linux
```bash
curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/gft-onboarding.sh -o gft-onboarding.sh
chmod +x gft-onboarding.sh
./gft-onboarding.sh
```

#### Windows (PowerShell)
```powershell
curl -L https://raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/onboarding-win.ps1 -o onboarding-win.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\onboarding-win.ps1
```
*Note: The Windows script bootstraps WSL2/Ubuntu before launching the bash orchestrator.*

## Validation

After installation, verify your environment using the provided scripts:

```bash
./validate-environment.sh        # Verify role-specific tools
./validate-devops-environment.sh # Verify DevOps tooling baseline
```

## Troubleshooting

- **Logs**: Detailed execution logs are saved to `~/gft_onboarding_<timestamp>.log`.
- **Support**: Contact the DevOps Enablement Guild or check `#devops-support` on Slack.

---

*For architecture details and developer-specific workflows, see [AGENTS.md](./AGENTS.md).*
