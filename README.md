---
docId: GC-README-IDX-030
title: Readme
version: 1.0.0
status: Draft
authors:
  - AI Compliance Agent
reviewers:
  - ReviewTeamPlaceholder
creation_date: '2025-05-25'
language: en
summary: This directory houses DevOps automation scripts for the GenCr@ft project, streamlining onboarding and other development workflows. Scripts are provided for automating tasks and improving efficiency within the GenCr@ft ecosystem.
tags:
  - devops-automation
  - gencraft
  - onboarding
  - scripts
  - automation
  - devops
  - gencraft
last_updated_date: '2025-06-05'
---

# GenCr@t Studio - Onboarding Scripts

![Status: V2 Approved](https://img.shields.io/badge/status-V2%20Approved-brightgreen)

## 1. Overview

Welcome to GenCr@t Studio! This repository contains the official onboarding scripts designed to automate the setup of your local development environment.

The primary script, `v2/gft-onboarding.sh`, is a comprehensive tool that configures your machine with the necessary software, tools, and configurations based on your specific role within the studio. It is entirely driven by our Single Source of Truth (SSoT) repository, `gcs-devops-standards`, ensuring your environment is always compliant with our latest standards.

## 2. Prerequisites

Before running the onboarding script, please ensure your system meets the following prerequisites.

### 2.1. Supported Operating Systems

- **macOS:** (zsh)
- **Linux:** Debian/Ubuntu derivatives (apt) or Fedora-based (dnf).
- **Windows 10/11:** Via **Windows Subsystem for Linux 2 (WSL2)**.

### 2.2. For Windows Users (Important First Step)

If you are on Windows, you must first prepare your machine by running our PowerShell bootstrapper. This will install and configure WSL2 correctly.

1. Open PowerShell **as an Administrator**.
2. Navigate to the `v1/` directory (where the legacy scripts are).
3. Allow script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
4. Run the bootstrapper: `.\onboarding-win.ps1`
5. Follow the on-screen instructions. At the end, a WSL2 terminal will open. **All subsequent steps must be performed inside this WSL2 terminal.**

### 2.3. Core Dependencies

The onboarding script itself requires two tools to be installed first:

- **Git:** To clone our SSoT repository.
- **yq:** A command-line YAML processor to read the SSoT.

You can install them with your system's package manager:

```bash
  # On macOS
  brew install git yq

  # On Debian/Ubuntu
  sudo apt update && sudo apt install git yq -y
```

## 3. How to Use

  Once the prerequisites are met, follow these steps from your terminal (or your WSL2 terminal on Windows):

**Step 1.** Clone this repository:

  ```bash
    git clone [URL_of_this_gcd-onboarding-scripts_repo]
    cd gcd-onboarding-scripts/v2
  ```

**Step 2.** Make the script executable:

  ```Bash
    chmod +x gft-onboarding.sh
  ```

**Step 3.** Run the script:

  ```Bash
    ./gft-onboarding.sh
  ```

The script is interactive and will guide you through the process, starting with selecting your role in the studio.

## 4. Script Behavior

When you run the script, it will perform the following actions based on the role you select:

- **Fetch SSoT:** Clones or updates a local copy of `gcs-devops-standards`.
- **Install Tools:** Installs required command-line tools and version managers (e.g., `nvm`, `pyenv`) according to your role's profile.
- **Configure Git:** Prompts for your `user.name` and `user.email` and sets up global configurations.
- **Set up SSH:** Guides you through creating or using an SSH key and adding it to your GitHub account.
- **Install Global Git Hooks:** Configures a global `commit-msg` hook to enforce our Conventional Commits standard on all your local repositories.
- **Install VS Code Extensions:** Automatically installs the recommended VS Code extensions for your role.
- **Clone Repositories:** Clones the essential studio repositories for your role into a central workspace (`~/gft_studio`).

## 5. Validation

At any time after the onboarding, you can run the validation script to check if your environment is compliant with the latest standards.

```Bash
  # Navigate to the script directory
  cd ~/gft_studio/gcd-onboarding-scripts/v2

  # Run the validator
  ./validate-environment.sh
```

This will run a series of checks and provide a summary report of any missing tools or misconfigurations.

## 6. Contribution

This script is a living project. If you wish to contribute, please follow the standards defined in gcs-devops-standards, including creating a new branch, using Conventional Commits, and submitting a Pull Request for review by the DevOps team.
