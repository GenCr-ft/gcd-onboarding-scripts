#!/usr/bin/env bash
# includes/07_preflight.sh
# Workspace-aware environment readiness preflight.
# Sourced by gft-onboarding.sh. Public entry point: run_preflight().

# Mockable low-level helpers — tests override these to avoid real subprocess calls
_pf_has_command()          { command -v "$1" >/dev/null 2>&1; }
_pf_check_connectivity()   { curl -s --max-time 5 https://github.com >/dev/null 2>&1; }
_pf_check_gh_auth()        { gh auth status >/dev/null 2>&1; }
_pf_check_org_membership() {
    local login
    login=$(gh api user --jq .login 2>/dev/null) || return 1
    gh api "orgs/GenCr-ft/members/${login}" --silent >/dev/null 2>&1
}
_pf_free_disk_gb() {
    # df -k is portable (Linux + macOS); result in 1K blocks → convert to GB
    df -k "$HOME" 2>/dev/null | awk 'NR==2{printf "%d", $4/1048576}'
}
_pf_git_user_name()        { git config --global user.name 2>/dev/null; }
_pf_git_user_email()       { git config --global user.email 2>/dev/null; }
_pf_cmd_version()          { "$1" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }

# Populated by _pf_build_checks. Each element: "label|status|action|pkg"
PREFLIGHT_RESULTS=()

# Public entry point
run_preflight() {
    log_info "Running environment preflight..."

    if ! _pf_check_connectivity; then
        log_error "No internet connectivity. Check your network connection and re-run."
        return 1
    fi
}
