# Preflight Environment Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `includes/07_preflight.sh` — a workspace-aware preflight that prints a readiness table, asks permission before installing anything, and exits cleanly on unresolved critical failures.

**Architecture:** New file sourced last in the `source` block of `gft-onboarding.sh`. Internal low-level helpers (`_pf_*`) wrap every external call so tests can override them without PATH tricks. A `PREFLIGHT_RESULTS` indexed array carries `"label|status|action|pkg"` entries from check phase through render and resolve phases. The existing `check_prerequisites()` call in `main()` is replaced by `run_preflight`.

**Tech Stack:** bash (≥ 3.2 compatible — no `declare -A`), existing `log_*` helpers and `confirm_action` from `01_helpers.sh`, `install_with_package_manager` from `00_bootstrap.sh`.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| CREATE | `includes/07_preflight.sh` | All preflight logic |
| MODIFY | `gft-onboarding.sh` | Add `source` line; replace `check_prerequisites` call with `run_preflight` |
| MODIFY | `tests/test_onboarding_logic.sh` | Add 10 preflight test suites + register in `main()` |

---

## Task 1: Stub `07_preflight.sh` and wire into `gft-onboarding.sh`

**Files:**
- Create: `includes/07_preflight.sh`
- Modify: `gft-onboarding.sh`

- [ ] **Step 1: Create the stub**

```bash
cat > includes/07_preflight.sh << 'EOF'
#!/usr/bin/env bash
# ID: GFT_ONBOARDING_PREFLIGHT_07
# Title: Onboarding Script - Environment Readiness Preflight
# Version: 1.0.0
# Description: Workspace-aware preflight: renders readiness table, asks
#   permission before installing, exits on unresolved critical failures.

# --- Mockable low-level helpers ---
_pf_has_command()        { command -v "$1" >/dev/null 2>&1; }
_pf_check_connectivity() { curl -s --max-time 5 https://github.com >/dev/null 2>&1; }
_pf_check_gh_auth()      { gh auth status >/dev/null 2>&1; }
_pf_check_org_membership() {
    local login
    login=$(gh api user --jq .login 2>/dev/null) || return 1
    gh api "orgs/GenCr-ft/members/${login}" --silent >/dev/null 2>&1
}
_pf_free_disk_gb()       { df -BG "$HOME" 2>/dev/null | awk 'NR==2{gsub("G",""); print $4}'; }
_pf_git_user_name()      { git config --global user.name 2>/dev/null; }
_pf_git_user_email()     { git config --global user.email 2>/dev/null; }
_pf_cmd_version()        { "$1" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }

# Placeholder — logic added in subsequent tasks
run_preflight() { :; }
EOF
```

- [ ] **Step 2: Wire `07_preflight.sh` into `gft-onboarding.sh`**

After the existing `source "${INCLUDES_DIR}/06_workspace_files.sh"` line, add:

```bash
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/07_preflight.sh"
```

In `main()`, replace:

```bash
check_prerequisites
```

with:

```bash
run_preflight
```

- [ ] **Step 3: Verify existing tests still pass**

```bash
bash ./test.sh
```

Expected: `✅ ALL TEST SUITES PASSED.`

- [ ] **Step 4: Commit**

```bash
git add includes/07_preflight.sh gft-onboarding.sh
git commit -F - <<'EOF'
feat(onboarding): issue-118 — stub 07_preflight.sh and wire into main

Adds the empty run_preflight stub and replaces check_prerequisites call.
All existing test suites pass. Behaviour unchanged until preflight logic lands.
EOF
```

---

## Task 2: Connectivity check (T-9)

**Files:**
- Modify: `includes/07_preflight.sh`
- Modify: `tests/test_onboarding_logic.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/test_onboarding_logic.sh` (before the `main()` function):

```bash
test_preflight_connectivity_hard_fail() {
    log_info "[TEST SUITE 19] Preflight: connectivity hard fail..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    # Override: simulate offline
    _pf_check_connectivity() { return 1; }

    local output exit_code
    output=$(run_preflight 2>&1) || exit_code=$?

    [[ "${exit_code:-0}" -ne 1 ]] && \
        log_error "FAIL: run_preflight should exit 1 when offline. Got: ${exit_code:-0}" && return 1
    [[ "$output" != *"No internet connectivity"* ]] && \
        log_error "FAIL: expected 'No internet connectivity' message. Got: $output" && return 1

    log_success "Preflight connectivity hard fail: PASSED"
}
```

Also register it in `main()`:

```bash
test_preflight_connectivity_hard_fail || ((failed_suites++))
```

- [ ] **Step 2: Run to verify it fails**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep -E "FAIL|PASS|FATAL" | tail -5
```

Expected: `FAIL: run_preflight should exit 1 when offline`

- [ ] **Step 3: Implement connectivity check in `run_preflight`**

Replace the stub `run_preflight` in `07_preflight.sh`:

```bash
run_preflight() {
    log_info "Running environment preflight..."

    # U-1: connectivity — hard exit before table
    if ! _pf_check_connectivity; then
        log_error "No internet connectivity. Cannot reach https://github.com"
        log_error "Check your network connection and re-run."
        return 1
    fi
    log_info "Internet connectivity: OK"
}
```

- [ ] **Step 4: Run tests to verify T-9 passes**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep -E "FAIL|✅"
```

Expected: `✅ ALL TEST SUITES PASSED.`

- [ ] **Step 5: Commit**

```bash
git add includes/07_preflight.sh tests/test_onboarding_logic.sh
git commit -F - <<'EOF'
test(onboarding): issue-118 red: T-9 connectivity hard fail
EOF
git add includes/07_preflight.sh
git commit -F - <<'EOF'
feat(onboarding): issue-118 green: T-9 connectivity hard fail exits 1 with message
EOF
```

---

## Task 3: Check collection and table render (T-1, T-2)

**Files:**
- Modify: `includes/07_preflight.sh`
- Modify: `tests/test_onboarding_logic.sh`

- [ ] **Step 1: Write T-1 and T-2 failing tests**

Add to `tests/test_onboarding_logic.sh`:

```bash
test_preflight_table_all_pass() {
    log_info "[TEST SUITE 20] Preflight: table renders with all-pass..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()    { return 0; }
    _pf_has_command()           { return 0; }   # every tool present
    _pf_check_gh_auth()         { return 0; }
    _pf_check_org_membership()  { return 0; }
    _pf_free_disk_gb()          { echo "50"; }
    _pf_git_user_name()         { echo "Dev"; }
    _pf_git_user_email()        { echo "dev@example.com"; }
    GFT_WORKSPACE=""

    local output
    output=$(run_preflight 2>&1)
    local exit_code=$?

    [[ $exit_code -ne 0 ]] && \
        log_error "FAIL: all-pass preflight should exit 0. Got: $exit_code" && return 1
    [[ "$output" != *"All checks passed"* ]] && \
        log_error "FAIL: expected 'All checks passed'. Got: $output" && return 1
    [[ "$output" == *"MISSING"* ]] && \
        log_error "FAIL: no MISSING rows expected in all-pass. Got: $output" && return 1

    log_success "Preflight table all-pass: PASSED"
}

test_preflight_table_mixed() {
    log_info "[TEST SUITE 21] Preflight: table renders mixed pass/fail..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command() {
        case "$1" in
            gh) return 1 ;;   # gh missing
            *)  return 0 ;;
        esac
    }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    # Suppress the interactive resolve step for this render-only test
    _pf_resolve_issues()       { return 0; }

    local output
    output=$(run_preflight 2>&1)

    [[ "$output" != *"gh (GitHub CLI)"* ]] && \
        log_error "FAIL: table should include 'gh (GitHub CLI)' row. Got: $output" && return 1
    [[ "$output" != *"MISSING"* ]] && \
        log_error "FAIL: expected MISSING status in output. Got: $output" && return 1
    [[ "$output" != *"item(s) need attention"* ]] && \
        log_error "FAIL: expected attention summary. Got: $output" && return 1

    log_success "Preflight table mixed: PASSED"
}
```

Register both in `main()`:

```bash
test_preflight_table_all_pass || ((failed_suites++))
test_preflight_table_mixed    || ((failed_suites++))
```

- [ ] **Step 2: Run to verify both fail**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep "FAIL:" | head -5
```

Expected: FAIL on both new suites.

- [ ] **Step 3: Implement check collection and table render in `07_preflight.sh`**

Add these functions before `run_preflight`:

```bash
# Returns workspace-specific tool specs for a given workspace id.
# Each line: "display_label:cmd:min_major_version:pkg"
# min_major_version empty = any version
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

# Populates PREFLIGHT_RESULTS array.
# Each entry: "label|status|action|pkg"
# status: OK WARN MISSING UNAUTH UNSET NOMEM SKIPPED
# action: none install auth identity_name identity_email org disk
_pf_build_checks() {
    PREFLIGHT_RESULTS=()

    # Universal tools (U-3 – U-8)
    local -a tools=(
        "git:git:git"
        "curl:curl:curl"
        "gh (GitHub CLI):gh:gh"
        "python3 >= 3.9:python3:python3"
        "yq:yq:yq"
        "unzip:unzip:unzip"
    )
    local spec label cmd pkg
    for spec in "${tools[@]}"; do
        label="${spec%%:*}"; spec="${spec#*:}"
        cmd="${spec%%:*}";   pkg="${spec##*:}"
        if _pf_has_command "$cmd"; then
            PREFLIGHT_RESULTS+=("$label|OK|none|")
        else
            PREFLIGHT_RESULTS+=("$label|MISSING|install|$pkg")
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

    # U-13: disk space
    local free_gb
    free_gb=$(_pf_free_disk_gb)
    if [[ -n "$free_gb" ]] && (( free_gb < 2 )); then
        PREFLIGHT_RESULTS+=("disk space >= 2 GB|NOMEM|disk|")
    else
        PREFLIGHT_RESULTS+=("disk space >= 2 GB|OK|none|")
    fi

    # Workspace-specific tools
    if [[ -n "${GFT_WORKSPACE:-}" ]]; then
        while IFS= read -r spec; do
            [[ -z "$spec" ]] && continue
            label="${spec%%:*}"; spec="${spec#*:}"
            cmd="${spec%%:*}";   spec="${spec#*:}"
            local min_ver="${spec%%:*}"
            pkg="${spec##*:}"
            if _pf_has_command "$cmd"; then
                # Version gate: if min_ver set, check major version
                if [[ -n "$min_ver" ]]; then
                    local ver
                    ver=$(_pf_cmd_version "$cmd" 2>/dev/null || echo "0")
                    local major="${ver%%.*}"
                    if (( major < min_ver )); then
                        PREFLIGHT_RESULTS+=("$label|WARN (v${ver} < ${min_ver})|install|$pkg")
                        continue
                    fi
                fi
                PREFLIGHT_RESULTS+=("$label|OK|none|")
            else
                PREFLIGHT_RESULTS+=("$label|MISSING|install|$pkg")
            fi
        done < <(_pf_workspace_checks_for "${GFT_WORKSPACE}")
    fi
}

_pf_render_table() {
    local c1=24 c2=13 c3=15
    local sep="+$(printf '%*s' $((c1+2)) '' | tr ' ' '-')+$(printf '%*s' $((c2+2)) '' | tr ' ' '-')+$(printf '%*s' $((c3+2)) '' | tr ' ' '-')+"
    local _G="${GFT_COLOR_GREEN:-\033[1;32m}"
    local _R="${GFT_COLOR_RED:-\033[1;31m}"
    local _Y="${GFT_COLOR_YELLOW:-\033[1;33m}"
    local _N="${GFT_COLOR_RESET:-\033[0m}"

    echo "$sep"
    printf "| %-${c1}s | %-${c2}s | %-${c3}s |\n" "Check" "Status" "Action"
    echo "$sep"

    local fail_count=0
    local entry label status action color status_disp action_disp
    for entry in "${PREFLIGHT_RESULTS[@]}"; do
        label="${entry%%|*}";  entry="${entry#*|}"
        status="${entry%%|*}"; entry="${entry#*|}"
        action="${entry%%|*}"

        case "$status" in
            OK)      color="$_G"; status_disp="OK";         action_disp="--" ;;
            MISSING) color="$_R"; status_disp="MISSING";    action_disp="install?"; ((fail_count++)) ;;
            UNAUTH)  color="$_R"; status_disp="UNAUTH";     action_disp="login?";   ((fail_count++)) ;;
            UNSET)   color="$_R"; status_disp="UNSET";      action_disp="prompt";   ((fail_count++)) ;;
            NOMEM)   color="$_Y"; status_disp="LOW MEM";    action_disp="warn" ;;
            SKIPPED) color="$_Y"; status_disp="SKIPPED";    action_disp="skipped" ;;
            WARN*)   color="$_Y"; status_disp="${status}";  action_disp="upgrade?" ;;
            *)       color="";    status_disp="$status";    action_disp="?" ;;
        esac

        printf "| %-${c1}s | ${color}%-${c2}s${_N} | %-${c3}s |\n" \
            "$label" "$status_disp" "$action_disp"
    done
    echo "$sep"

    local summary_width=$(( c1 + c2 + c3 + 6 ))
    if (( fail_count > 0 )); then
        printf "| %-${summary_width}s |\n" "${fail_count} item(s) need attention"
    else
        printf "| %-${summary_width}s |\n" "All checks passed"
    fi
    echo "$sep"

    return $fail_count
}

# Stubbed resolve — replaced in Task 4
_pf_resolve_issues() { return 0; }
```

Update `run_preflight`:

```bash
run_preflight() {
    log_info "Running environment preflight..."

    if ! _pf_check_connectivity; then
        log_error "No internet connectivity. Cannot reach https://github.com"
        log_error "Check your network connection and re-run."
        return 1
    fi

    _pf_build_checks
    local fail_count
    _pf_render_table || fail_count=$?

    if (( ${fail_count:-0} == 0 )); then
        log_success "Environment ready. Starting onboarding..."
        return 0
    fi

    _pf_resolve_issues
}
```

- [ ] **Step 4: Run tests**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep -E "FAIL:|✅"
```

Expected: `✅ ALL TEST SUITES PASSED.`

- [ ] **Step 5: Commit**

```bash
git add includes/07_preflight.sh tests/test_onboarding_logic.sh
git commit -F - <<'EOF'
test(onboarding): issue-118 red: T-1 T-2 table render
EOF
git add includes/07_preflight.sh
git commit -F - <<'EOF'
feat(onboarding): issue-118 green: T-1 T-2 check collection and table render
EOF
```

---

## Task 4: Install prompt Y/N (T-3, T-4)

**Files:**
- Modify: `includes/07_preflight.sh`
- Modify: `tests/test_onboarding_logic.sh`

- [ ] **Step 1: Write T-3 and T-4 failing tests**

Add to `tests/test_onboarding_logic.sh`:

```bash
test_preflight_install_prompt_yes() {
    log_info "[TEST SUITE 22] Preflight: install prompt Y triggers install..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    local install_called=""
    _pf_check_connectivity()   { return 0; }
    _pf_has_command() { [[ "$1" == "gh" ]] && return 1 || return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    install_with_package_manager() { install_called="$1"; return 0; }
    GFT_WORKSPACE=""
    # Simulate user answering Y
    GFT_NON_INTERACTIVE="true"

    local output
    output=$(run_preflight 2>&1)
    local exit_code=$?

    [[ $exit_code -ne 0 ]] && \
        log_error "FAIL: exit code should be 0 after Y install. Got: $exit_code. Output: $output" && return 1
    [[ "$install_called" != "gh" ]] && \
        log_error "FAIL: install_with_package_manager should be called with 'gh'. Got: '${install_called}'" && return 1

    log_success "Preflight install prompt Y: PASSED"
}

test_preflight_install_prompt_no() {
    log_info "[TEST SUITE 23] Preflight: install prompt N marks SKIPPED and exits 1..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command() { [[ "$1" == "gh" ]] && return 1 || return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    # Simulate user answering N for all prompts
    confirm_action() { return 1; }

    local output exit_code
    output=$(run_preflight 2>&1) || exit_code=$?

    [[ "${exit_code:-0}" -ne 1 ]] && \
        log_error "FAIL: should exit 1 after declining install. Got: ${exit_code:-0}" && return 1
    [[ "$output" != *"SKIPPED"* ]] && \
        log_error "FAIL: expected SKIPPED in output. Got: $output" && return 1
    [[ "$output" != *"required checks failed"* ]] && \
        log_error "FAIL: expected failure summary. Got: $output" && return 1

    log_success "Preflight install prompt N: PASSED"
}
```

Register in `main()`:

```bash
test_preflight_install_prompt_yes || ((failed_suites++))
test_preflight_install_prompt_no  || ((failed_suites++))
```

- [ ] **Step 2: Run to verify both fail**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep "FAIL:" | grep -i "install"
```

- [ ] **Step 3: Implement `_pf_resolve_issues` in `07_preflight.sh`**

Replace the stub `_pf_resolve_issues()`:

```bash
_pf_resolve_issues() {
    local i entry label status action pkg
    for i in "${!PREFLIGHT_RESULTS[@]}"; do
        entry="${PREFLIGHT_RESULTS[$i]}"
        label="${entry%%|*}";  entry="${entry#*|}"
        status="${entry%%|*}"; entry="${entry#*|}"
        action="${entry%%|*}"; pkg="${entry##*|}"

        case "$action" in
            install)
                if confirm_action "Missing '${label}'. Install it?"; then
                    install_with_package_manager "$pkg" "${pkg}"
                    if _pf_has_command "${pkg}"; then
                        PREFLIGHT_RESULTS[$i]="${label}|OK|none|"
                    fi
                else
                    PREFLIGHT_RESULTS[$i]="${label}|SKIPPED|none|"
                fi
                ;;
            auth)
                if confirm_action "GitHub CLI is not authenticated. Run 'gh auth login' now?"; then
                    gh auth login
                    if _pf_check_gh_auth; then
                        PREFLIGHT_RESULTS[$i]="${label}|OK|none|"
                    fi
                else
                    PREFLIGHT_RESULTS[$i]="${label}|SKIPPED|none|"
                fi
                ;;
            identity_name)
                local name
                printf "git user.name is not set. Enter your name: "
                read -r name
                git config --global user.name "$name"
                PREFLIGHT_RESULTS[$i]="${label}|OK|none|"
                ;;
            identity_email)
                local email
                printf "git user.email is not set. Enter your email: "
                read -r email
                git config --global user.email "$email"
                PREFLIGHT_RESULTS[$i]="${label}|OK|none|"
                ;;
            org)
                log_warn "You must be a GenCr-ft org member."
                log_warn "Request access: https://github.com/orgs/GenCr-ft/discussions"
                printf "Press Enter once you have been added, or Ctrl-C to abort: "
                read -r
                if _pf_check_org_membership; then
                    PREFLIGHT_RESULTS[$i]="${label}|OK|none|"
                else
                    PREFLIGHT_RESULTS[$i]="${label}|SKIPPED|none|"
                fi
                ;;
            disk)
                if ! confirm_action "Disk space is low (< 2 GB free). Continue anyway?"; then
                    log_error "Onboarding aborted: insufficient disk space."
                    return 1
                fi
                ;;
        esac
    done

    # Re-render with resolved statuses and check for remaining failures
    local fail_count
    _pf_render_table || fail_count=$?

    if (( ${fail_count:-0} > 0 )); then
        log_error "${fail_count} required checks failed. Please resolve them and re-run."
        return 1
    fi

    log_success "Environment ready. Starting onboarding..."
    return 0
}
```

Also update `run_preflight` to propagate the exit code from `_pf_resolve_issues`:

```bash
run_preflight() {
    log_info "Running environment preflight..."

    if ! _pf_check_connectivity; then
        log_error "No internet connectivity. Cannot reach https://github.com"
        log_error "Check your network connection and re-run."
        return 1
    fi

    _pf_build_checks
    local fail_count
    _pf_render_table || fail_count=$?

    if (( ${fail_count:-0} == 0 )); then
        log_success "Environment ready. Starting onboarding..."
        return 0
    fi

    _pf_resolve_issues
}
```

- [ ] **Step 4: Run tests**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep -E "FAIL:|✅"
```

Expected: `✅ ALL TEST SUITES PASSED.`

- [ ] **Step 5: Commit**

```bash
git add includes/07_preflight.sh tests/test_onboarding_logic.sh
git commit -F - <<'EOF'
test(onboarding): issue-118 red: T-3 T-4 install prompt Y/N
EOF
git add includes/07_preflight.sh
git commit -F - <<'EOF'
feat(onboarding): issue-118 green: T-3 T-4 install prompt resolves or marks SKIPPED
EOF
```

---

## Task 5: GitHub auth spawn (T-5)

**Files:**
- Modify: `tests/test_onboarding_logic.sh`

(No changes to `07_preflight.sh` — the `auth` branch in `_pf_resolve_issues` is already written.)

- [ ] **Step 1: Write T-5 failing test**

Add to `tests/test_onboarding_logic.sh`:

```bash
test_preflight_gh_auth_prompts_login() {
    log_info "[TEST SUITE 24] Preflight: unauth gh prompts gh auth login..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    local gh_login_called=false
    _pf_check_connectivity()   { return 0; }
    _pf_has_command()          { return 0; }
    _pf_check_gh_auth()        { return 1; }   # unauthenticated
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    # Answer Y to auth prompt; mock gh auth login and re-check
    confirm_action()   { return 0; }
    gh() {
        if [[ "$1 $2" == "auth login" ]]; then
            gh_login_called=true
            # After "login", pretend auth now passes
            _pf_check_gh_auth() { return 0; }
            return 0
        fi
        command gh "$@" 2>/dev/null || true
    }

    local output
    output=$(run_preflight 2>&1)
    local exit_code=$?

    [[ $exit_code -ne 0 ]] && \
        log_error "FAIL: should exit 0 after successful auth. Got: $exit_code. $output" && return 1
    [[ "$gh_login_called" != "true" ]] && \
        log_error "FAIL: gh auth login was not called." && return 1

    log_success "Preflight gh auth prompts login: PASSED"
}
```

Register:

```bash
test_preflight_gh_auth_prompts_login || ((failed_suites++))
```

- [ ] **Step 2: Run to verify it fails**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep "FAIL:" | grep -i auth
```

- [ ] **Step 3: Run tests — should pass without code changes**

The `auth` branch in `_pf_resolve_issues` already calls `gh auth login`. Verify:

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep -E "FAIL:|✅"
```

Expected: `✅ ALL TEST SUITES PASSED.`

- [ ] **Step 4: Commit**

```bash
git add tests/test_onboarding_logic.sh
git commit -F - <<'EOF'
test(onboarding): issue-118 red+green: T-5 gh auth login subprocess verified
EOF
```

---

## Task 6: Workspace-specific checks (T-6, T-7)

**Files:**
- Modify: `tests/test_onboarding_logic.sh`

(No changes to `07_preflight.sh` — `_pf_workspace_checks_for` and the workspace loop in `_pf_build_checks` are already written.)

- [ ] **Step 1: Write T-6 and T-7 failing tests**

Add to `tests/test_onboarding_logic.sh`:

```bash
test_preflight_workspace_aethel_checks_node_docker() {
    log_info "[TEST SUITE 25] Preflight: aethel workspace adds node and docker rows..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command()          { return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    _pf_cmd_version()          { echo "22.1.0"; }  # node >= 20
    GFT_WORKSPACE="aethel"

    local output
    output=$(run_preflight 2>&1)

    [[ "$output" != *"node >= 20"* ]] && \
        log_error "FAIL: expected 'node >= 20' row for aethel. Got: $output" && return 1
    [[ "$output" != *"docker"* ]] && \
        log_error "FAIL: expected 'docker' row for aethel. Got: $output" && return 1

    log_success "Preflight workspace aethel node+docker: PASSED"
}

test_preflight_no_workspace_no_extra_checks() {
    log_info "[TEST SUITE 26] Preflight: no workspace omits workspace-specific rows..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command()          { return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""

    local output
    output=$(run_preflight 2>&1)

    [[ "$output" == *"node >= 20"* ]] && \
        log_error "FAIL: 'node >= 20' row should be absent when no workspace. Got: $output" && return 1
    [[ "$output" == *"docker"* ]] && \
        log_error "FAIL: 'docker' row should be absent when no workspace. Got: $output" && return 1

    log_success "Preflight no workspace no extra checks: PASSED"
}
```

Register:

```bash
test_preflight_workspace_aethel_checks_node_docker || ((failed_suites++))
test_preflight_no_workspace_no_extra_checks        || ((failed_suites++))
```

- [ ] **Step 2: Run to verify both fail**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep "FAIL:" | grep -i "workspace\|node\|docker"
```

- [ ] **Step 3: Run tests — should pass without code changes**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep -E "FAIL:|✅"
```

Expected: `✅ ALL TEST SUITES PASSED.`

- [ ] **Step 4: Commit**

```bash
git add tests/test_onboarding_logic.sh
git commit -F - <<'EOF'
test(onboarding): issue-118 red+green: T-6 T-7 workspace-specific check rows
EOF
```

---

## Task 7: Critical failure exit and disk space warning (T-8, T-10)

**Files:**
- Modify: `tests/test_onboarding_logic.sh`

- [ ] **Step 1: Write T-8 and T-10 failing tests**

Add to `tests/test_onboarding_logic.sh`:

```bash
test_preflight_critical_fail_exits_one() {
    log_info "[TEST SUITE 27] Preflight: unresolved critical failure exits 1 with summary..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command() { [[ "$1" == "gh" ]] && return 1 || return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    confirm_action() { return 1; }  # decline all

    local output exit_code
    output=$(run_preflight 2>&1) || exit_code=$?

    [[ "${exit_code:-0}" -ne 1 ]] && \
        log_error "FAIL: should exit 1 with unresolved critical check. Got: ${exit_code:-0}" && return 1
    [[ "$output" != *"required checks failed"* ]] && \
        log_error "FAIL: expected 'required checks failed' summary. Got: $output" && return 1

    log_success "Preflight critical fail exits 1: PASSED"
}

test_preflight_disk_warn_non_blocking() {
    log_info "[TEST SUITE 28] Preflight: low disk triggers warn, user can continue..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command()          { return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "1"; }   # below 2 GB threshold
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    confirm_action() { return 0; }  # answer Y to continue

    local output
    output=$(run_preflight 2>&1)
    local exit_code=$?

    [[ $exit_code -ne 0 ]] && \
        log_error "FAIL: low disk + Y should exit 0. Got: $exit_code. $output" && return 1
    [[ "$output" != *"LOW MEM"* ]] && \
        log_error "FAIL: expected LOW MEM in table. Got: $output" && return 1

    log_success "Preflight disk warn non-blocking: PASSED"
}
```

Register:

```bash
test_preflight_critical_fail_exits_one  || ((failed_suites++))
test_preflight_disk_warn_non_blocking   || ((failed_suites++))
```

- [ ] **Step 2: Run to verify both fail**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep "FAIL:" | grep -i "critical\|disk"
```

- [ ] **Step 3: Run tests**

```bash
bash tests/test_onboarding_logic.sh 2>&1 | grep -E "FAIL:|✅"
```

Expected: `✅ ALL TEST SUITES PASSED.`

- [ ] **Step 4: Commit**

```bash
git add tests/test_onboarding_logic.sh
git commit -F - <<'EOF'
test(onboarding): issue-118 red+green: T-8 T-10 exit logic and disk space warning
EOF
```

---

## Task 8: Full integration — run `./test.sh` and push

- [ ] **Step 1: Run the full test suite**

```bash
bash ./test.sh
```

Expected:

```
✅ ALL TEST SUITES PASSED.
```

- [ ] **Step 2: Fix any failures** (investigate with `bash tests/test_onboarding_logic.sh` if full suite differs)

- [ ] **Step 3: Push and open PR**

```bash
git push -u origin feat/issue-118-preflight
gh pr create \
  --repo GenCr-ft/gcd-onboarding-scripts \
  --head feat/issue-118-preflight \
  --base main \
  --title "feat(onboarding): issue-118 — workspace-aware preflight env readiness" \
  --body "## Summary
Adds \`includes/07_preflight.sh\`: connectivity check, full readiness table, Y/N install prompts, workspace-specific tool rows, clean exit on unresolved failures.

## AC Coverage
- AC-1 table rendered before any install ✅
- AC-2 decline → SKIPPED → exit 1 ✅
- AC-3 gh auth login spawned on Y ✅
- AC-4 workspace-specific rows for aethel / workspace-ops ✅
- AC-5 all 10 test suites pass ✅

Closes #118"
```

---

## Self-Review Checklist

- [x] T-1 all-pass render → Task 3
- [x] T-2 mixed render → Task 3
- [x] T-3 install Y → Task 4
- [x] T-4 install N → exit 1 → Task 4
- [x] T-5 gh auth login → Task 5
- [x] T-6 workspace aethel → Task 6
- [x] T-7 no workspace → Task 6
- [x] T-8 critical exit 1 → Task 7
- [x] T-9 connectivity hard fail → Task 2
- [x] T-10 disk warn → Task 7
- [x] `run_preflight` wired into `main()` → Task 1
- [x] `check_prerequisites` call replaced → Task 1
- [x] No `declare -A` (bash 3 compat) → uses indexed arrays throughout
- [x] `GFT_NON_INTERACTIVE` respected in T-3 via `confirm_action` → existing helper handles it
- [x] `_pf_resolve_issues` stub present at parse time → defined before `run_preflight` calls it
