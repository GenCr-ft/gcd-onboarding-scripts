#!/usr/bin/env bash

# ==============================================================================
# Test Harness (Final Regression Version)
# ==============================================================================

# --- Setup ---
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"
source "${PROJECT_ROOT}/includes/01_helpers.sh"
source "${PROJECT_ROOT}/includes/02_installers.sh"

# --- Mocks ---
install_with_package_manager() { echo "MOCK_install_with_pkg_mgr_CALLED_FOR:$1"; }
verify_docker() { echo "MOCK_verify_docker_CALLED"; }
install_commitlint() { echo "MOCK_install_commitlint_CALLED"; }
# Mocks from previous steps
install_node() { echo "MOCK_install_node_CALLED_WITH:$1"; }
install_python() { echo "MOCK_install_python_CALLED_WITH:$1"; }
install_binary_from_github() { echo "MOCK_install_binary_CALLED_WITH:$1 $2"; }
install_aws_cli() { echo "MOCK_install_aws_cli_CALLED"; }
install_hook_managers() { echo "MOCK_install_hook_managers_CALLED"; }
get_ssot_tool_version() {
    case "$1" in
        nodejs) echo "lts-gallium" ;; python) echo "3.11.5" ;; opentofu) echo "1.6.0" ;; *) echo "" ;;
    esac
}

# --- Integration Test ---
test_full_dispatcher_logic() {
    log_info "[VALIDATION] Testing full dispatcher logic for 'devops-specialist' role..."
    local mock_matrix_path="${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md"
    ROLE_MATRIX_YAML=$(sed -n '/```yaml/,/```/p' "$mock_matrix_path" | sed '1d;$d')
    export ROLE_MATRIX_YAML

    local output
    output=$(install_tools_for_role "devops-specialist" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Test FAILED: install_tools_for_role exited with a non-zero status."
        echo "$output" && return 1
    fi

    # --- Verification ---
    local checks_failed=0
    # Check for each tool required by the mock role matrix
    [[ "$output" != *"MOCK_install_commitlint_CALLED"* ]] && log_error "FAIL: commitlint not processed." && ((checks_failed++))
    [[ "$output" != *"MOCK_verify_docker_CALLED"* ]] && log_error "FAIL: docker not processed." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_node_CALLED_WITH:lts-gallium"* ]] && log_error "FAIL: node-lts not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_binary_CALLED_WITH:opentofu 1.6.0"* ]] && log_error "FAIL: opentofu not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_python_CALLED_WITH:3.11.5"* ]] && log_error "FAIL: python not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_with_pkg_mgr_CALLED_FOR:shellcheck"* ]] && log_error "FAIL: shellcheck not processed." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_with_pkg_mgr_CALLED_FOR:yq"* ]] && log_error "FAIL: yq not processed." && ((checks_failed++))

    if [[ $checks_failed -ne 0 ]]; then
        log_error "$checks_failed check(s) failed."
        echo "--- Raw Test Output ---" && echo "$output" && return 1
    fi

    log_success "All required tools for 'devops-specialist' were processed correctly by the dispatcher."
    return 0
}

# --- Test Runner ---
if test_full_dispatcher_logic; then
    log_success "✅ [MISSION COMPLETE] The SSoT-driven installer feature is fully implemented and validated."
    exit 0
else
    log_error "🔴 Final validation failed."
    exit 1
fi
