#!/usr/bin/env bash
set -euo pipefail

# Shared tooling (gcs-plt-tools) installs once into the studio home
# (~/.gft-studio, override GFT_STUDIO_HOME) per ENG-ADR-088, not the workspace.
GFT_DIR="${GFT_STUDIO_HOME:-$HOME/.gft-studio}/gcs-plt-tools/services/gft"

# High-level workspace help block printed during bootstrap/no-poetry scenarios
print_workspace_help() {
  echo "GenCr@ft Studio Workspace Launcher"
  echo "=================================="
  echo "This workspace contains five bounded developer domains:"
  echo "  - aethel           : Aethel Game (Client, Server, PCG, auth, persistence)"
  echo "  - evai-platform    : Platform tools & DevSphere CLI orchestration"
  echo "  - workspace-ops    : Onboarding scripts & DevOps compliance checks"
  echo "  - agent-factory    : AI Gem operational guidelines & personas"
  echo "  - studio-gencraft  : Studio handbooks, legal, and standards"
  echo ""
  echo "Usage:"
  echo "  ./workspace.sh [command] [workspace-id]"
  echo ""
  echo "To fully activate the local CLI tool suite, ensure you run onboarding:"
  echo "  cd gcd-onboarding-scripts && ./gft-onboarding.sh"
}

# If help is explicitly requested, print help and exit 0
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  print_workspace_help
  exit 0
fi

# If a command is requested, but Poetry/gft surface is missing during early checkout
if ! command -v poetry >/dev/null 2>&1 || [[ ! -d "${GFT_DIR}" ]]; then
  print_workspace_help
  echo "" >&2
  echo "Error: Poetry is not installed or the gft toolchain is not built." >&2
  echo "Please run onboarding to activate local CLI commands:" >&2
  echo "  cd gcd-onboarding-scripts && ./gft-onboarding.sh" >&2
  exit 1
fi

cd "${GFT_DIR}"

if [[ "$#" -eq 0 ]]; then
  exec poetry run gft workspace menu
fi

exec poetry run gft workspace "$@"
