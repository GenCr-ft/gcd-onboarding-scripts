#!/usr/bin/env bash
# Test suite for WI-211: install_node, install_python, setup_ssh_key error-handling & remediation guidance.

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"
export GFT_SSOT_PATH="${TEST_SCRIPT_PATH}/fixtures/mock_ssot"

source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
source "${PROJECT_ROOT}/includes/01_helpers.sh"
source "${PROJECT_ROOT}/includes/02_installers.sh"
source "${PROJECT_ROOT}/includes/03_configuration.sh"

# Stubs for functions not under test
confirm_action() { return 0; }
get_ssot_tool_version() {
    case "$1" in nodejs) echo "lts-iron" ;; python) echo "3.11.5" ;; opentofu) echo "1.6.0" ;; *) echo "" ;; esac
}
detect_os_arch() { GFT_OS="linux"; GFT_ARCH="amd64"; export GFT_OS GFT_ARCH; }

# ==============================================================================
# Cycle 1 — AC-1: empty version → [ERROR] "check role tooling matrix", no [SUCCESS]
# ==============================================================================
test_install_node_empty_version_guard() {
    local checks_failed=0
    local tmp_home; tmp_home=$(mktemp -d)
    trap 'rm -rf "$tmp_home"' RETURN
    mkdir -p "$tmp_home/.nvm"
    # nvm.sh stub — never sourced for empty-version path (guard fires first)
    printf '#!/usr/bin/env bash\nnvm() { return 0; }\n' > "$tmp_home/.nvm/nvm.sh"

    local output
    output=$(HOME="$tmp_home" install_node "" 2>&1) || true

    [[ "$output" == *"check role tooling matrix"* ]] || \
        { log_error "FAIL: AC-1: expected 'check role tooling matrix' in output; got: $output"; ((checks_failed++)); }
    [[ "$output" != *"[SUCCESS]"* ]] || \
        { log_error "FAIL: AC-1: [SUCCESS] must not appear; got: $output"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] install_node empty version guard: PASSED"
}

# ==============================================================================
# Cycle 2 — AC-2: nvm chain failure → no [SUCCESS], [ERROR] present
# ==============================================================================
test_install_node_nvm_chain_failure() {
    local checks_failed=0
    local tmp_home; tmp_home=$(mktemp -d)
    trap 'rm -rf "$tmp_home"' RETURN
    mkdir -p "$tmp_home/.nvm"
    # File-based stub: '. "$HOME/.nvm/nvm.sh"' overrides any bash-function stub set before call.
    printf '#!/usr/bin/env bash\nnvm() { return 1; }\n' > "$tmp_home/.nvm/nvm.sh"

    local output
    output=$(HOME="$tmp_home" install_node "20.0.0" 2>&1) || true

    [[ "$output" != *"installed and set as default"* ]] || \
        { log_error "FAIL: AC-2: success message must not appear when nvm fails; got: $output"; ((checks_failed++)); }
    [[ "$output" == *"installation via nvm failed"* ]] || \
        { log_error "FAIL: AC-2: error message must appear when nvm fails; got: $output"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] install_node nvm chain failure: PASSED"
}

# ==============================================================================
# --- Test Runner ---
# ==============================================================================
# ==============================================================================
# Cycle 3 — AC-3: pyenv missing → [ERROR] + install URL; dispatcher || trap fixed
# ==============================================================================
test_install_python_pyenv_missing() {
    local checks_failed=0

    local output
    output=$(PATH="/usr/bin:/bin" install_python "3.11.5" 2>&1) || true

    [[ "$output" == *"https://pyenv.run"* ]] || \
        { log_error "FAIL: AC-3: expected pyenv install URL; got: $output"; ((checks_failed++)); }
    [[ "$output" != *"installed and set as global default"* ]] || \
        { log_error "FAIL: AC-3: success message must not appear; got: $output"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] install_python pyenv missing: PASSED"
}

# Dispatcher: failing install_python must NOT emit the "No version" warning
test_dispatcher_python_failure_no_false_warn() {
    local checks_failed=0

    # Override install_python to simulate failure; version IS available from SSoT stub
    install_python() { return 1; }

    local output
    output=$(install_tool "python" 2>&1) || true

    unset -f install_python

    [[ "$output" != *"No version for 'python' in SSoT"* ]] || \
        { log_error "FAIL: AC-3b: dispatcher emitted false [WARN] on installer failure; got: $output"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] dispatcher python failure no false warn: PASSED"
}

main() {
    local failed_suites=0

    test_install_node_empty_version_guard          || ((failed_suites++))
    test_install_node_nvm_chain_failure            || ((failed_suites++))
    test_install_python_pyenv_missing              || ((failed_suites++))
    test_dispatcher_python_failure_no_false_warn   || ((failed_suites++))

    echo "-------------------------------------------"
    if [[ $failed_suites -ne 0 ]]; then
        log_error "🔴 $failed_suites TEST SUITE(S) FAILED." && exit 1
    else
        log_success "✅ ALL TEST SUITES PASSED." && exit 0
    fi
}

main
