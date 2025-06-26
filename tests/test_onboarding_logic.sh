#!/usr/bin/env bash

# ==============================================================================
# Test Harness (Final Regression Version)
# ==============================================================================

# --- Setup ---
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"

# Ces variables sont normalement dans gft-onboarding.sh, nous les répliquons ici pour le test.
readonly GFT_SSOT_REPO="https://github.com/GenCr-ft/gcs-devops-standards.git"
# Utiliser un chemin de cache différent pour les tests pour éviter les conflits
readonly GFT_SSOT_PATH="/tmp/gft-ssot-onboarding-test"



source "${PROJECT_ROOT}/includes/01_helpers.sh"
source "${PROJECT_ROOT}/includes/02_installers.sh"
source "${PROJECT_ROOT}/includes/03_configuration.sh"

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
        nodejs) echo "lts-gallium" ;;
        python) echo "3.11.5" ;;
        opentofu) echo "1.6.0" ;;
        *) echo "" ;;
    esac
}


gh() {
    # This mock simply prints the arguments it received, allowing us to test it.
    echo "MOCK_gh_CALLED_WITH: $*"
}

# Generic mocks
confirm_action() { return 0; } # Auto-confirm "yes"


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

# Test Suite 2: Repository Cloning Logic
test_repository_cloning_logic() {
    log_info "[TEST SUITE 2] Testing Repository Cloning Logic..."

    local output
    output=$(clone_repositories_for_role "devops-specialist" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Test FAILED: clone_repositories_for_role exited with a non-zero status."
        echo "$output" && return 1
    fi

    local checks_failed=0
    # Check for a repo from common-base
    if [[ "$output" != *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/gcs-devops-standards"* ]]; then
        log_error "FAIL (Repo): 'gcs-devops-standards' was not cloned." && ((checks_failed++))
    fi
    # Check for a repo from lead-developer-tech-lead
    if [[ "$output" != *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/gct-service-template-py"* ]]; then
        log_error "FAIL (Repo): 'gct-service-template-py' was not cloned." && ((checks_failed++))
    fi
    # Check for a repo from devops-specialist itself
    if [[ "$output" != *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/gencraft-iac"* ]]; then
        log_error "FAIL (Repo): 'gencraft-iac' was not cloned." && ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then
        log_error "$checks_failed repository check(s) failed."
        echo "--- Raw Repo Test Output ---" && echo "$output" && return 1
    fi

    log_success "Repository Cloning Logic: PASSED"
    return 0
}

# ==============================================================================
# --- Test Runner ---
# ==============================================================================
main() {
    # Load the MOCK data into the environment variable. This is the ONLY source of data for the tests.
    local mock_matrix_path="${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md"
    ROLE_MATRIX_YAML=$(sed -n '/```yaml/,/```/p' "$mock_matrix_path" | sed '1d;$d')
    export ROLE_MATRIX_YAML

    if [ -z "$ROLE_MATRIX_YAML" ]; then
        log_error "FATAL: Could not load YAML from mock file '$mock_matrix_path'. The 'sed' command failed."
        exit 1
    fi

    local failed_suites=0

    test_full_dispatcher_logic || ((failed_suites++))
    test_repository_cloning_logic || ((failed_suites++))

    echo "-------------------------------------------"
    if [[ $failed_suites -ne 0 ]]; then
        log_error "🔴 $failed_suites TEST SUITE(S) FAILED."
        exit 1
    else
        log_success "✅ ALL TEST SUITES PASSED."
        exit 0
    fi
}

# --- Main Execution Block ---
main
