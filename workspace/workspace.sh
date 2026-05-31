#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GFT_DIR="${ROOT}/gcs-plt-tools/services/gft"

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

# If help is requested, or if Poetry/gft surface is missing during early checkout
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]] || ! command -v poetry >/dev/null 2>&1 || [[ ! -d "${GFT_DIR}" ]]; then
  print_workspace_help
  exit 0
fi

cd "${GFT_DIR}"

if [[ "$#" -eq 0 ]]; then
  exec poetry run gft workspace menu
fi

exec poetry run gft workspace "$@"
