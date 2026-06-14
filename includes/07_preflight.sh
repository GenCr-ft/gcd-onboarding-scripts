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

# Returns workspace-specific tool spec lines for the given workspace.
# Each line format: "display_label:cmd:min_major:pkg"
# min_major empty = any version accepted
_pf_workspace_checks_for() {
    case "${1:-}" in
        aethel|agent-factory)
            printf '%s\n' "node >= 20:node:20:nodejs" "docker:docker::docker" ;;
        evai-platform)
            printf '%s\n' "node >= 20:node:20:nodejs" "docker:docker::docker" "cargo (rust):cargo::cargo" ;;
        workspace-ops|studio-gencraft)
            printf '%s\n' "node >= 20:node:20:nodejs" ;;
        *) ;;
    esac
}

_pf_build_checks() {
    PREFLIGHT_RESULTS=()

    # Universal tools (U-3 to U-8)
    local _tools _spec _label _cmd _pkg
    _tools=(
        "git:git:git"
        "curl:curl:curl"
        "gh (GitHub CLI):gh:gh"
        "python3 >= 3.9:python3:python3"
        "yq:yq:yq"
        "unzip:unzip:unzip"
    )
    for _spec in "${_tools[@]}"; do
        _label="${_spec%%:*}"; _spec="${_spec#*:}"
        _cmd="${_spec%%:*}";   _pkg="${_spec##*:}"
        if _pf_has_command "$_cmd"; then
            PREFLIGHT_RESULTS+=("${_label}|OK|none|")
        else
            PREFLIGHT_RESULTS+=("${_label}|MISSING|install|${_pkg}")
        fi
    done

    # U-9: gh auth
    if _pf_check_gh_auth; then
        PREFLIGHT_RESULTS+=("gh auth|OK|none|")
    else
        PREFLIGHT_RESULTS+=("gh auth|UNAUTH|auth|")
    fi

    # U-10, U-11: git identity
    if [[ -n "$(_pf_git_user_name)" ]]; then
        PREFLIGHT_RESULTS+=("git user.name|OK|none|")
    else
        PREFLIGHT_RESULTS+=("git user.name|UNSET|identity_name|")
    fi
    if [[ -n "$(_pf_git_user_email)" ]]; then
        PREFLIGHT_RESULTS+=("git user.email|OK|none|")
    else
        PREFLIGHT_RESULTS+=("git user.email|UNSET|identity_email|")
    fi

    # U-12: org membership
    if _pf_check_org_membership; then
        PREFLIGHT_RESULTS+=("GenCr-ft org|OK|none|")
    else
        PREFLIGHT_RESULTS+=("GenCr-ft org|MISSING|org|")
    fi

    # U-13: disk space (warn if < 2 GB)
    local _free_gb
    _free_gb=$(_pf_free_disk_gb)
    if [[ -n "$_free_gb" ]] && (( _free_gb < 2 )); then
        PREFLIGHT_RESULTS+=("disk space >= 2 GB|NOMEM|disk|")
    else
        PREFLIGHT_RESULTS+=("disk space >= 2 GB|OK|none|")
    fi

    # Workspace-specific tools (loaded only when GFT_WORKSPACE is set)
    if [[ -n "${GFT_WORKSPACE:-}" ]]; then
        local _ws_spec _ws_label _ws_cmd _ws_min _ws_pkg
        while IFS= read -r _ws_spec; do
            [[ -z "$_ws_spec" ]] && continue
            _ws_label="${_ws_spec%%:*}"; _ws_spec="${_ws_spec#*:}"
            _ws_cmd="${_ws_spec%%:*}";   _ws_spec="${_ws_spec#*:}"
            _ws_min="${_ws_spec%%:*}";   _ws_pkg="${_ws_spec##*:}"
            if _pf_has_command "$_ws_cmd"; then
                if [[ -n "$_ws_min" ]]; then
                    local _ver _major
                    _ver=$(_pf_cmd_version "$_ws_cmd" 2>/dev/null || echo "0")
                    _major="${_ver%%.*}"
                    if (( _major < _ws_min )); then
                        PREFLIGHT_RESULTS+=("${_ws_label}|WARN (v${_ver} < ${_ws_min})|install|${_ws_pkg}")
                        continue
                    fi
                fi
                PREFLIGHT_RESULTS+=("${_ws_label}|OK|none|")
            else
                PREFLIGHT_RESULTS+=("${_ws_label}|MISSING|install|${_ws_pkg}")
            fi
        done < <(_pf_workspace_checks_for "${GFT_WORKSPACE}")
    fi
}

_pf_render_table() {
    local _c1=24 _c2=11 _c3=12
    local _G="${GFT_COLOR_GREEN:-\033[1;32m}"
    local _R="${GFT_COLOR_RED:-\033[1;31m}"
    local _Y="${GFT_COLOR_YELLOW:-\033[1;33m}"
    local _N="${GFT_COLOR_RESET:-\033[0m}"
    local _sep="+$(printf '%*s' $((_c1+2)) '' | tr ' ' '-')+$(printf '%*s' $((_c2+2)) '' | tr ' ' '-')+$(printf '%*s' $((_c3+2)) '' | tr ' ' '-')+"

    printf "\n%s\n" "$_sep"
    printf "| %-${_c1}s | %-${_c2}s | %-${_c3}s |\n" "Check" "Status" "Action"
    printf "%s\n" "$_sep"

    local _fail_count=0 _entry _label _status _action _color _sdisp _adisp
    for _entry in "${PREFLIGHT_RESULTS[@]}"; do
        _label="${_entry%%|*}";  _entry="${_entry#*|}"
        _status="${_entry%%|*}"; _entry="${_entry#*|}"
        _action="${_entry%%|*}"

        case "$_status" in
            OK)      _color="$_G"; _sdisp="OK";      _adisp="--" ;;
            MISSING) _color="$_R"; _sdisp="MISSING"; _adisp="install?"; ((_fail_count++)) ;;
            UNAUTH)  _color="$_R"; _sdisp="UNAUTH";  _adisp="login?";   ((_fail_count++)) ;;
            UNSET)   _color="$_R"; _sdisp="UNSET";   _adisp="prompt";   ((_fail_count++)) ;;
            NOMEM)   _color="$_Y"; _sdisp="LOW MEM"; _adisp="warn" ;;
            SKIPPED) _color="$_Y"; _sdisp="SKIPPED"; _adisp="skipped" ;;
            WARN*)   _color="$_Y"; _sdisp="WARN";    _adisp="upgrade?" ;;
            *)       _color="";   _sdisp="$_status"; _adisp="?" ;;
        esac

        # Apply color outside printf's width specifier so ANSI bytes don't count toward padding
        printf "| %-${_c1}s | ${_color}%-${_c2}s${_N} | %-${_c3}s |\n" \
            "$_label" "$_sdisp" "$_adisp"
    done

    local _sum_width=$((_c1 + _c2 + _c3 + 6))
    printf "%s\n" "$_sep"
    if (( _fail_count > 0 )); then
        printf "| %-${_sum_width}s |\n" "${_fail_count} item(s) need attention"
    else
        printf "| %-${_sum_width}s |\n" "All checks passed"
    fi
    printf "%s\n\n" "$_sep"

    return $_fail_count
}

# Stubbed resolve — replaced in Task 4
_pf_resolve_issues() { return 0; }

# Public entry point
run_preflight() {
    log_info "Running environment preflight..."

    if ! _pf_check_connectivity; then
        log_error "No internet connectivity. Check your network connection and re-run."
        return 1
    fi

    _pf_build_checks
    local _fail_count
    _pf_render_table || _fail_count=$?

    if (( ${_fail_count:-0} == 0 )); then
        log_success "Environment ready. Starting onboarding..."
        return 0
    fi

    _pf_resolve_issues
}
