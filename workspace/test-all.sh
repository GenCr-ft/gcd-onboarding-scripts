#!/usr/bin/env bash
# test-all.sh — workspace test orchestrator; delegates to each repo's ./test.sh
#
# Usage:
#   ./test-all.sh                     run all groups
#   ./test-all.sh --server            TypeScript server + library repos only
#   ./test-all.sh --pcg               PCG (Rust + Python) only
#   ./test-all.sh --client            Godot GUT tests only
#   ./test-all.sh --ops               ops tooling repos only
#   ./test-all.sh --aethel            Aethel Game workspace tests
#   ./test-all.sh --evai-platform     EVAI Platform workspace tests
#   ./test-all.sh --workspace-ops     Workspace Operations tests
#   ./test-all.sh --agent-factory     Agent Factory tests
#   ./test-all.sh --studio-gencraft   Studio GenCraft tests
#   ./test-all.sh --no-integration    unit tests only (default: forward --integration)
#   ./test-all.sh --coverage          forward --coverage to each repo
#   ./test-all.sh --help              show this message
#
# Groups:
#   server  gcp-aethel-server  gcl-srv-persistence  gcl-srv-authentication
#           gcl-voxel-engine   gcl-ui-components
#   pcg     gcp-aethel-pcg
#   client  gcp-aethel-client
#   ops     gcs-plt-tools  gcd-ops-scripts  gcd-onboarding-scripts
#
# Prerequisites:
#   All repos must have ./test.sh (ENG-PLAN-TESTSH / PROJ-109).
#   Run ./onboard.sh in each repo before running tests.

set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0; SKIP=0

# Repos in Aethel Game Workspace (aethel)
AETHEL_REPOS=(
  "gcp-aethel-server"
  "gcl-srv-persistence"
  "gcl-srv-authentication"
  "gcp-aethel-pcg"
  "gcp-aethel-client"
  "gcl-voxel-engine"
  "gcl-ui-components"
  "gcp-aethel-architecture"
  "gcp-aethel-backlog"
  "gcp-aethel-docs-gdd"
  "gcp-aethel-docs-lw"
  "gcp-aethel-docs-req"
  "gcp-aethel-docs-external"
)

# Repos in EVAI Platform Workspace (evai-platform)
EVAI_REPOS=(
  "gcs-plt-tools"
  "gcs-plt-docs-req"
)

# Repos in Workspace Operations Workspace (workspace-ops)
OPS_REPOS=(
  "gcd-onboarding-scripts"
  "gcd-ops-scripts"
  "gcd-shared-actions"
  "gcd-backup-utilities"
  "gencraft-iac"
)

# Repos in Agent Factory Workspace (agent-factory)
FACTORY_REPOS=(
  "gcs-plt-gemop"
  "gcs-plt-gembp"
)

# Repos in Studio GenCraft Workspace (studio-gencraft)
STUDIO_REPOS=(
  "gcs-core-governance"
  "gcs-engineering-handbook"
  "gcs-core-governance"
  "gcs-security-core"
  "gcs-studio-legal"
  "gcs-project-management"
  "gencr-ft.github.io"
  "gct-repo-template-standard"
  "gct-service-template-py"
  "gct-ssot-templates"
)

# ─── flags ────────────────────────────────────────────────────────────────────
RUN_AETHEL=0; RUN_EVAI=0; RUN_OPS_WS=0; RUN_FACTORY=0; RUN_STUDIO=0; ANY_WS_SELECTED=0
RUN_SERVER=0; RUN_PCG=0; RUN_CLIENT=0; RUN_OPS=0; ANY_LEGACY_SELECTED=0
RUN_INTEGRATION=1; RUN_COVERAGE=0

for arg in "$@"; do
  case "$arg" in
    --aethel)            RUN_AETHEL=1; ANY_WS_SELECTED=1 ;;
    --evai-platform)     RUN_EVAI=1; ANY_WS_SELECTED=1 ;;
    --workspace-ops)     RUN_OPS_WS=1; ANY_WS_SELECTED=1 ;;
    --agent-factory)     RUN_FACTORY=1; ANY_WS_SELECTED=1 ;;
    --studio-gencraft)   RUN_STUDIO=1; ANY_WS_SELECTED=1 ;;
    --server)            RUN_SERVER=1; ANY_LEGACY_SELECTED=1 ;;
    --pcg)               RUN_PCG=1; ANY_LEGACY_SELECTED=1 ;;
    --client)            RUN_CLIENT=1; ANY_LEGACY_SELECTED=1 ;;
    --ops)               RUN_OPS=1; ANY_LEGACY_SELECTED=1 ;;
    --no-integration)    RUN_INTEGRATION=0 ;;
    --coverage)          RUN_COVERAGE=1 ;;
    --help|-h)
      sed -n '2,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'; exit 0 ;;
  esac
done

# Check for conflicting selectors (cannot mix workspace and legacy technical selectors)
if [[ "$ANY_WS_SELECTED" == "1" ]] && [[ "$ANY_LEGACY_SELECTED" == "1" ]]; then
  echo "Error: Conflicting selectors. You cannot mix workspace selectors (--aethel, --evai-platform, etc.)" >&2
  echo "       with legacy technical selectors (--server, --pcg, --client, --ops)." >&2
  exit 1
fi

# Default: if no selectors passed, run all legacy groups
if [[ "$ANY_WS_SELECTED" == "0" ]] && [[ "$ANY_LEGACY_SELECTED" == "0" ]]; then
  RUN_SERVER=1
  RUN_PCG=1
  RUN_CLIENT=1
  RUN_OPS=1
fi

# Build flags to forward to each repo's ./test.sh
REPO_FLAGS=()
[[ "$RUN_INTEGRATION" == "1" ]] && REPO_FLAGS+=("--integration")
[[ "$RUN_COVERAGE"    == "1" ]] && REPO_FLAGS+=("--coverage")

# ─── output helpers ───────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'; BOLD='\033[1m'

header() {
  echo -e "\n${BOLD}══════════════════════════════════════════════${NC}"
  echo -e "${BOLD}  $1${NC}"
  echo -e "${BOLD}══════════════════════════════════════════════${NC}"
}
pass() { echo -e "  ${GREEN}✓ PASS${NC}  $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC}  $1"; FAIL=$((FAIL+1)); }
skip() { echo -e "  ${YELLOW}⊘ SKIP${NC}  $1"; SKIP=$((SKIP+1)); }

# ─── run_repo: delegate to a single repo's ./test.sh ─────────────────────────
run_repo() {
  local repo="$1"
  local dir="${WORKSPACE}/${repo}"

  if [[ ! -d "$dir" ]]; then
    skip "$repo — directory not found"
    return
  fi
  if [[ ! -f "${dir}/test.sh" ]]; then
    skip "$repo — no test.sh (run ENG-PLAN-TESTSH)"
    return
  fi

  echo "  → ${repo}…"
  if (cd "$dir" && bash test.sh "${REPO_FLAGS[@]}" 2>&1); then
    pass "$repo"
  else
    fail "$repo"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Execution
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$ANY_WS_SELECTED" == "1" ]]; then
  if [[ "$RUN_AETHEL" == "1" ]]; then
    header "Aethel Game Workspace Tests"
    for r in "${AETHEL_REPOS[@]}"; do run_repo "$r"; done
  fi
  if [[ "$RUN_EVAI" == "1" ]]; then
    header "EVAI Platform Workspace Tests"
    for r in "${EVAI_REPOS[@]}"; do run_repo "$r"; done
  fi
  if [[ "$RUN_OPS_WS" == "1" ]]; then
    header "Workspace Operations Workspace Tests"
    for r in "${OPS_REPOS[@]}"; do run_repo "$r"; done
  fi
  if [[ "$RUN_FACTORY" == "1" ]]; then
    header "Agent Factory Workspace Tests"
    for r in "${FACTORY_REPOS[@]}"; do run_repo "$r"; done
  fi
  if [[ "$RUN_STUDIO" == "1" ]]; then
    header "Studio GenCraft Workspace Tests"
    for r in "${STUDIO_REPOS[@]}"; do run_repo "$r"; done
  fi
else
  # Legacy groups
  if [[ "$RUN_SERVER" == "1" ]]; then
    header "Server & Service Tests"
    run_repo "gcp-aethel-server"
    run_repo "gcl-srv-persistence"
    run_repo "gcl-srv-authentication"
    run_repo "gcl-voxel-engine"
    run_repo "gcl-ui-components"
  fi

  if [[ "$RUN_PCG" == "1" ]]; then
    header "PCG Tests (Rust + Python)"
    run_repo "gcp-aethel-pcg"
  fi

  if [[ "$RUN_CLIENT" == "1" ]]; then
    header "Godot GUT Tests"
    run_repo "gcp-aethel-client"
  fi

  if [[ "$RUN_OPS" == "1" ]]; then
    header "Ops Tooling Tests"
    run_repo "gcs-plt-tools"
    run_repo "gcd-ops-scripts"
    run_repo "gcd-onboarding-scripts"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════════════
header "Results"
echo -e "  ${GREEN}Passed:${NC}  $PASS"
[[ "$FAIL" -gt 0 ]] && echo -e "  ${RED}Failed:${NC}  $FAIL" || echo "  Failed:  $FAIL"
[[ "$SKIP" -gt 0 ]] && echo -e "  ${YELLOW}Skipped:${NC} $SKIP" || echo "  Skipped: $SKIP"
echo ""
if [[ "$FAIL" -gt 0 ]]; then
  echo -e "  ${RED}${BOLD}OVERALL: FAIL${NC}"
  exit 1
else
  echo -e "  ${GREEN}${BOLD}OVERALL: PASS${NC}"
  exit 0
fi
