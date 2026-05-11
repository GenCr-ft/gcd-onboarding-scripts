#!/usr/bin/env bash
# test-all.sh — workspace test orchestrator; delegates to each repo's ./test.sh
#
# Usage:
#   ./test-all.sh                     run all groups
#   ./test-all.sh --server            TypeScript server + library repos only
#   ./test-all.sh --pcg               PCG (Rust + Python) only
#   ./test-all.sh --client            Godot GUT tests only
#   ./test-all.sh --ops               ops tooling repos only
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

# ─── flags ────────────────────────────────────────────────────────────────────
RUN_SERVER=1; RUN_PCG=1; RUN_CLIENT=1; RUN_OPS=1
RUN_INTEGRATION=1; RUN_COVERAGE=0

for arg in "$@"; do
  case "$arg" in
    --server)         RUN_SERVER=1; RUN_PCG=0; RUN_CLIENT=0; RUN_OPS=0 ;;
    --pcg)            RUN_SERVER=0; RUN_PCG=1; RUN_CLIENT=0; RUN_OPS=0 ;;
    --client)         RUN_SERVER=0; RUN_PCG=0; RUN_CLIENT=1; RUN_OPS=0 ;;
    --ops)            RUN_SERVER=0; RUN_PCG=0; RUN_CLIENT=0; RUN_OPS=1 ;;
    --no-integration) RUN_INTEGRATION=0 ;;
    --coverage)       RUN_COVERAGE=1 ;;
    --help|-h)
      sed -n '2,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'; exit 0 ;;
  esac
done

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
# Group 1 — Server & services
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_SERVER" == "1" ]]; then
  header "Server & Service Tests"
  run_repo "gcp-aethel-server"
  run_repo "gcl-srv-persistence"
  run_repo "gcl-srv-authentication"
  run_repo "gcl-voxel-engine"
  run_repo "gcl-ui-components"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Group 2 — PCG
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_PCG" == "1" ]]; then
  header "PCG Tests (Rust + Python)"
  run_repo "gcp-aethel-pcg"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Group 3 — Godot client
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_CLIENT" == "1" ]]; then
  header "Godot GUT Tests"
  run_repo "gcp-aethel-client"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Group 4 — Ops tooling
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_OPS" == "1" ]]; then
  header "Ops Tooling Tests"
  run_repo "gcs-plt-tools"
  run_repo "gcd-ops-scripts"
  run_repo "gcd-onboarding-scripts"
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
