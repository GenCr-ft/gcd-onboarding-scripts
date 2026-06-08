# CLAUDE.md — gcd-onboarding-scripts

> **Note:** This repo has migrated. `AGENTS.md` is the authoritative source for all agent instructions and technical internals. Refer there first.

## Project Overview
SSoT-driven onboarding script suite for GenCr@ft Studio. Automates local development environment setup by consuming standards from `gcs-devops-standards`.

## Prerequisites
- Bash (Linux/macOS) or PowerShell (Windows)
- Git, Curl, Python 3
- GitHub account with access to GenCr-ft org

## Commands
- `./gft-onboarding.sh`: Main entry point for Linux/macOS.
- `./validate-environment.sh`: Verify local setup.
- `./setup-local-tofu-env.sh`: Configure OpenTofu backend.

## Structure
- `includes/`: Modular bash libraries and Python logic.
- `spec/`: Developer onboarding specification document.
- `tests/`: Unit and regression tests (bash-based, no external test runner).

## Notes
- Relies on `/tmp/gft-ssot-onboarding` as a local cache of the standards repo.
- Always run `validate-environment.sh` after making changes to the onboarding logic.
