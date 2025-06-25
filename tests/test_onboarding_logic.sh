#!/usr/bin/env bash

# Test harness for the Gencraft Onboarding Script
# This script is designed to be self-contained and run from the project root.
# Usage: ./tests/test_onboarding_logic.sh

# --- Setup: Robust Path Detection ---
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)

# Source the helpers and installers using a reliable path
source "${PROJECT_ROOT}/includes/01_helpers.sh"
source "${PROJECT_ROOT}/includes/02_installers.sh"

# --- Mock SSoT Configuration ---
ROLE_MATRIX_YAML=$(sed -n '/```yaml/,/```/p' "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md" | sed '1d;$d')
export ROLE_MATRIX_YAML

# --- Mocks & Stubs ---
install_tool() {
    echo "INSTALL_TOOL_CALLED_FOR:$1"
}

# --- Test Cases ---
test_devops_role_triggers_correct_tools() {
    log_info "Running test: DevOps role should trigger tofu, shellcheck, commitlint..."

    local output
    output=$(install_tools_for_role "devops-specialist" 2>&1)

    if [[ "$output" != *"INSTALL_TOOL_CALLED_FOR:opentofu"* ]]; then
        log_error "Test failed: 'opentofu' was not called for devops-specialist."
        return 1
    fi
    if [[ "$output" != *"INSTALL_TOOL_CALLED_FOR:shellcheck"* ]]; then
        log_error "Test failed: 'shellcheck' was not called for devops-specialist."
        return 1
    fi
    if [[ "$output" != *"INSTALL_TOOL_CALLED_FOR:commitlint"* ]]; then
        log_error "Test failed: 'commitlint' was not called for devops-specialist."
        return 1
    fi

    log_success "Test passed."
    return 0
}

test_gameplay_programmer_triggers_correct_tools() {
    log_info "Running test: Gameplay Programmer role should trigger python..."

    local output
    output=$(install_tools_for_role "gameplay-programmer" 2>&1)

    if [[ "$output" != *"INSTALL_TOOL_CALLED_FOR:python"* ]]; then
        log_error "Test failed: 'python' was not called for gameplay-programmer."
        return 1
    fi
    if [[ "$output" == *"INSTALL_TOOL_CALLED_FOR:opentofu"* ]]; then
        log_error "Test failed: 'opentofu' was called for gameplay-programmer but should not have been."
        return 1
    fi

    log_success "Test passed."
    return 0
}

# --- Test Runner ---
run_all_tests() {
    echo "--- Running Onboarding Script Logic Tests ---"
    local overall_status=0
    test_devops_role_triggers_correct_tools || overall_status=1
    test_gameplay_programmer_triggers_correct_tools || overall_status=1
    echo "-------------------------------------------"
    return $overall_status
}

# --- Main Execution Block ---
run_all_tests
TEST_RESULT=$?

if [ "$TEST_RESULT" -ne 0 ]; then
    echo "🔴 At least one test failed."
    exit 1
else
    echo "✅ All tests passed successfully."
    exit 0
fi
