#!/usr/bin/env bash
# E2E smoke tests for gft-onboarding.sh main() orchestration.
# Verifies the full orchestration sequence runs to completion with all
# external I/O (network, git, installs) stubbed out.

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"
export GFT_SSOT_PATH="${TEST_SCRIPT_PATH}/fixtures/mock_ssot"

source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
source "${PROJECT_ROOT}/includes/01_helpers.sh"
source "${PROJECT_ROOT}/includes/02_installers.sh"
source "${PROJECT_ROOT}/includes/03_configuration.sh"

# Minimal stub set shared across suites (mirrors test_onboarding_logic.sh baseline)
gh() { echo "MOCK_gh_CALLED_WITH: $*"; }
install_with_package_manager() { :; }
verify_docker() { :; }
install_commitlint() { :; }
install_node() { :; }
install_python() { :; }
install_binary_from_github() { :; }
confirm_action() { return 0; }
get_ssot_tool_version() { echo ""; }
python3() {
    local script_path="$1"; shift || true
    case "$script_path" in
        "${PROJECT_ROOT}/includes/get_role_tools.py") printf '%s\n' git github-cli; return 0;;
        "${PROJECT_ROOT}/includes/get_role_repos.py") return 0;;
        "${PROJECT_ROOT}/includes/get_role_env_vars.py") return 0;;
    esac
    command python3 "$script_path" "$@"
}

# ─── Suite E2E-1: exit-0, welcome greeting, completion banner, .bashrc artifact ─

test_main_exits_0_and_emits_welcome() {
    log_info "[TEST SUITE E2E-1] E2E: main() exits 0, emits welcome + completion, touches .bashrc..."
    local smoke_home; smoke_home=$(mktemp -d)
    local smoke_ws;   smoke_ws=$(mktemp -d)
    local smoke_out;  smoke_out=$(mktemp)
    trap "rm -rf '$smoke_home' '$smoke_ws'; rm -f '$smoke_out'; trap - RETURN" RETURN
    local exit_code=0
    (
        export HOME="$smoke_home"
        export GFT_PROJECTS_HOME="$smoke_ws"
        export GFT_ROLE="devops-specialist"
        export GFT_NON_INTERACTIVE="true"
        source "${PROJECT_ROOT}/gft-onboarding.sh"
        run_preflight()                      { :; }
        setup_ssot_repository()              { :; }
        load_ssot_configuration()            { :; }
        install_tools_for_role()             { :; }
        configure_git()                      { :; }
        setup_ssh_key()                      { :; }
        configure_environment_variables()    { touch "$HOME/.bashrc"; }
        install_vscode_extensions_for_role() { :; }
        clone_repositories_for_role()        { :; }
        install_gft_ops_scripts()            { :; }
        deploy_workspace_files()             { :; }
        deploy_planning_metadata_hook()      { :; }
        configure_agent_environment()        { :; }
        register_studio_hooks()              { :; }
        setup_pcg_python_venv()              { :; }
        configure_gft_cli()                  { :; }
        performance_and_caching()            { :; }
        final_validation()                   { :; }
        main
    ) > "$smoke_out" 2>&1 || exit_code=$?

    local checks_failed=0
    [[ $exit_code -ne 0 ]] \
        && log_error "FAIL: main() exited $exit_code (expected 0)" \
        && ((checks_failed++))
    grep -q "Welcome to the GenCr@ft Studio" "$smoke_out" \
        || { log_error "FAIL: welcome greeting not found in output"; ((checks_failed++)); }
    grep -q "Onboarding Complete" "$smoke_out" \
        || { log_error "FAIL: completion banner not found in output"; ((checks_failed++)); }
    [[ -f "$smoke_home/.bashrc" ]] \
        || { log_error "FAIL: configure_environment_variables did not produce .bashrc artifact"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then
        echo "--- smoke output ---" >&2 && cat "$smoke_out" >&2
        return 1
    fi
    log_success "E2E main() exits 0, welcome banner, .bashrc artifact: PASSED"
}

# ─── Suite E2E-2: main() aborts when run_preflight() fails ───────────────────

test_main_exits_nonzero_on_preflight_failure() {
    log_info "[TEST SUITE E2E-2] E2E: main() exits non-zero when run_preflight() returns 1..."
    local smoke_home; smoke_home=$(mktemp -d)
    local smoke_ws;   smoke_ws=$(mktemp -d)
    local smoke_out;  smoke_out=$(mktemp)
    trap "rm -rf '$smoke_home' '$smoke_ws'; rm -f '$smoke_out'; trap - RETURN" RETURN
    local exit_code=0
    (
        export HOME="$smoke_home"
        export GFT_PROJECTS_HOME="$smoke_ws"
        export GFT_ROLE="devops-specialist"
        export GFT_NON_INTERACTIVE="true"
        source "${PROJECT_ROOT}/gft-onboarding.sh"
        run_preflight() { exit 1; }
        main
    ) > "$smoke_out" 2>&1 || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_error "FAIL: main() returned 0 when run_preflight() failed (expected non-zero)"
        cat "$smoke_out" >&2
        return 1
    fi
    log_success "E2E main() aborts on preflight failure: PASSED"
}

# ─── Runner ──────────────────────────────────────────────────────────────────

main_runner() {
    local failed_suites=0
    test_main_exits_0_and_emits_welcome           || ((failed_suites++))
    test_main_exits_nonzero_on_preflight_failure  || ((failed_suites++))

    echo "-------------------------------------------"
    if [[ $failed_suites -eq 0 ]]; then
        log_success "✅ ALL E2E SMOKE SUITES PASSED."
        return 0
    else
        log_error "❌ $failed_suites E2E smoke suite(s) FAILED."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_runner "$@"
fi
