#!/usr/bin/env bash
# ==============================================================================
# Test: 4 canonical workspace ids + legacy aliases (WI-222, ENG-ADR-087)
# ==============================================================================
set -u
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/01_helpers.sh"

CANONICAL=(aethel gft-platform onboarding agent-ecosystem)
# legacy -> canonical
ALIASES=("evai-platform:gft-platform" "workspace-ops:onboarding" "agent-factory:agent-ecosystem" "studio-gencraft:gft-platform")

failed=0

test_canonical_ids_valid() {
    log_info "[TEST] canonical ids accepted"
    for ws in "${CANONICAL[@]}"; do
        if ! is_valid_workspace "$ws"; then
            log_error "FAIL: canonical workspace '$ws' rejected by is_valid_workspace"; ((failed++))
        fi
        if ! workspace_repositories "$ws" >/dev/null 2>&1; then
            log_error "FAIL: workspace_repositories has no entry for canonical '$ws'"; ((failed++))
        fi
        if ! workspace_role "$ws" >/dev/null 2>&1; then
            log_error "FAIL: workspace_role has no entry for canonical '$ws'"; ((failed++))
        fi
    done
}

test_aliases_canonicalize() {
    log_info "[TEST] legacy aliases canonicalize"
    for pair in "${ALIASES[@]}"; do
        local old="${pair%%:*}" new="${pair##*:}"
        if ! is_valid_workspace "$old"; then
            log_error "FAIL: legacy alias '$old' not accepted"; ((failed++))
        fi
        local got; got=$(canonicalize_workspace "$old")
        if [[ "$got" != "$new" ]]; then
            log_error "FAIL: canonicalize_workspace('$old')='$got', expected '$new'"; ((failed++))
        fi
    done
    # canonical ids canonicalize to themselves
    local self; self=$(canonicalize_workspace "onboarding")
    [[ "$self" == "onboarding" ]] || { log_error "FAIL: canonical id did not canonicalize to itself"; ((failed++)); }
}

test_quickstart_sets_canonical_workspace() {
    log_info "[TEST] parse_cli_args canonicalizes GFT_WORKSPACE"
    unset GFT_QUICKSTART GFT_WORKSPACE GFT_ROLE GFT_NON_INTERACTIVE
    parse_cli_args --quickstart --workspace workspace-ops >/dev/null 2>&1
    if [[ "${GFT_WORKSPACE:-}" != "onboarding" ]]; then
        log_error "FAIL: legacy 'workspace-ops' did not canonicalize GFT_WORKSPACE to 'onboarding' (got '${GFT_WORKSPACE:-}')"; ((failed++))
    fi
    unset GFT_QUICKSTART GFT_WORKSPACE GFT_ROLE GFT_NON_INTERACTIVE
}

test_unknown_rejected_lists_canonical() {
    log_info "[TEST] unknown id rejected, lists canonical ids"
    local err; err=$(mktemp)
    if parse_cli_args --quickstart --workspace bogus 2>"$err"; then
        log_error "FAIL: unknown workspace accepted"; ((failed++))
    fi
    for ws in "${CANONICAL[@]}"; do
        if ! grep -q "$ws" "$err"; then
            log_error "FAIL: error listing does not include canonical id '$ws'"; ((failed++))
        fi
    done
    rm -f "$err"
    unset GFT_QUICKSTART GFT_WORKSPACE GFT_ROLE GFT_NON_INTERACTIVE
}

test_help_shows_canonical() {
    log_info "[TEST] help lists canonical ids"
    local out; out=$(mktemp)
    parse_cli_args --help >"$out" 2>&1
    for ws in "${CANONICAL[@]}"; do
        if ! grep -q "$ws" "$out"; then
            log_error "FAIL: --help does not list canonical id '$ws'"; ((failed++))
        fi
    done
    rm -f "$out"
    unset GFT_SHOW_HELP_ONLY
}

test_canonical_ids_valid
test_aliases_canonicalize
test_quickstart_sets_canonical_workspace
test_unknown_rejected_lists_canonical
test_help_shows_canonical

if [[ $failed -ne 0 ]]; then
    log_error "🔴 test_canonical_workspaces: $failed check(s) failed."
    exit 1
fi
log_success "✅ test_canonical_workspaces: all checks passed."
