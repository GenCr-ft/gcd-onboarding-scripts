#!/usr/bin/env bash

# ==============================================================================
# Test Harness - Final Consolidated Version
# ==============================================================================

# --- Setup ---
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"
export GFT_SSOT_PATH="${TEST_SCRIPT_PATH}/fixtures/mock_ssot"

# Source all dependencies
source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
source "${PROJECT_ROOT}/includes/01_helpers.sh"
source "${PROJECT_ROOT}/includes/02_installers.sh"
source "${PROJECT_ROOT}/includes/03_configuration.sh"

# ==============================================================================
# --- Mocks ---
# ==============================================================================
# Mocks for Tool Installers
install_with_package_manager() { echo "MOCK_install_with_pkg_mgr_CALLED_FOR:$1"; }
verify_docker() { echo "MOCK_verify_docker_CALLED"; }
install_commitlint() { echo "MOCK_install_commitlint_CALLED"; }
install_node() { echo "MOCK_install_node_CALLED_WITH:$1"; }
install_python() { echo "MOCK_install_python_CALLED_WITH:$1"; }
install_binary_from_github() { echo "MOCK_install_binary_CALLED_WITH:$1 $2"; }
# Mock for Repo Cloning
gh() { echo "MOCK_gh_CALLED_WITH: $*"; }
# VS Code mock
code() {
    if [[ "$1" == "--list-extensions" ]]; then
        printf '%s\n' "${MOCK_CODE_INSTALLED_EXTS:-}"
    elif [[ "$1" == "--install-extension" ]]; then
        echo "MOCK_code_install:$2"
    fi
}
# Docker mock
docker() {
    echo "MOCK_docker_CALLED_WITH: $*"
    if [[ "$1" == "pull" ]]; then return 0; fi
}
# Generic mocks
confirm_action() { return 0; }
get_ssot_tool_version() { case "$1" in nodejs) echo "lts-gallium" ;; python) echo "3.11.5" ;; opentofu) echo "1.6.0" ;; *) echo "" ;; esac; }

python3() {
    local script_path="$1"
    shift || true
    case "$script_path" in
        "${PROJECT_ROOT}/includes/get_role_tools.py")
            printf '%s\n' \
                git github-cli python node-lts docker commitlint yq opentofu shellcheck
            return 0
            ;;
        "${PROJECT_ROOT}/includes/get_role_repos.py")
            if [[ -n "${MOCK_ROLE_REPO_OUTPUT:-}" ]]; then
                printf '%s\n' "${MOCK_ROLE_REPO_OUTPUT}"
                return 0
            fi
            ;;
        "${PROJECT_ROOT}/includes/get_role_env_vars.py")
            printf '%s\n' \
                'GFT_PROJECTS_HOME="$HOME/gft_studio"' \
                'GFT_LOG_LEVEL="INFO"' \
                'GFT_AWS_PROFILE="gft-devops"' \
                'TF_VAR_github_token=""'
            return 0
            ;;
    esac

    command python3 "$script_path" "$@"
}

# ==============================================================================
# --- Test Suites ---
# ==============================================================================

test_tool_installation_logic() {
    log_info "[TEST SUITE 1] Testing Tool Installation Logic..."
    local output; output=$(install_tools_for_role "devops-specialist" 2>&1)
    local checks_failed=0

    # Assertions for ALL expected tools for devops-specialist
    [[ "$output" != *"MOCK_install_commitlint_CALLED"* ]] && log_error "FAIL: commitlint not processed." && ((checks_failed++))
    [[ "$output" != *"MOCK_verify_docker_CALLED"* ]] && log_error "FAIL: docker not processed." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_node_CALLED_WITH:lts-gallium"* ]] && log_error "FAIL: node-lts not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_binary_CALLED_WITH:opentofu 1.6.0"* ]] && log_error "FAIL: opentofu not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_python_CALLED_WITH:3.11.5"* ]] && log_error "FAIL: python not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_with_pkg_mgr_CALLED_FOR:shellcheck"* ]] && log_error "FAIL: shellcheck not processed." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_with_pkg_mgr_CALLED_FOR:yq"* ]] && log_error "FAIL: yq not processed." && ((checks_failed++))

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw Tool Test Output ---" && echo "$output"; return 1; fi
    log_success "Tool Installation Logic: PASSED"
}

test_repository_cloning_logic() {
    log_info "[TEST SUITE 2] Testing Repository Cloning Logic..."
    local output; output=$(clone_repositories_for_role "devops-specialist" 2>&1)
    if [[ "$output" != *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/gcs-devops-standards"* ]]; then
        log_error "FAIL (Repo): 'gcs-devops-standards' was not cloned." && echo "$output" && return 1
    fi
    log_success "Repository Cloning Logic: PASSED"
}

test_base_repository_injection_when_missing() {
    log_info "[TEST SUITE 2b] Testing Base Repository Injection..."
    local previous_mock="$MOCK_ROLE_REPO_OUTPUT"
    MOCK_ROLE_REPO_OUTPUT=$'gcs-plt-tools\ngct-service-template-py\ngencraft-iac'
    local output; output=$(clone_repositories_for_role "devops-specialist" 2>&1)
    MOCK_ROLE_REPO_OUTPUT="$previous_mock"

    if [[ "$output" != *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/gcs-devops-standards"* ]]; then
        log_error "FAIL (Base Repo): 'gcs-devops-standards' was not injected when missing." && echo "$output" && return 1
    fi
    log_success "Base Repository Injection Logic: PASSED"
}

test_environment_variable_logic() {
    log_info "[TEST SUITE 3] Testing Environment Variable Logic..."
    local MOCK_PROFILE_FILE; MOCK_PROFILE_FILE=$(mktemp)
    local MOCK_HOME; MOCK_HOME=$(mktemp -d)
    trap "rm -f '$MOCK_PROFILE_FILE'; rm -rf '$MOCK_HOME'; trap - RETURN" RETURN
    
    # Temporarily override HOME for the test to verify directory creation
    local ORIGINAL_HOME="$HOME"
    export HOME="$MOCK_HOME"
    
    local output; output=$(configure_environment_variables "devops-specialist" "$MOCK_PROFILE_FILE" 2>&1)
    local checks_failed=0

    if ! grep -q 'export GFT_PROJECTS_HOME="$HOME/gft_studio"' "$MOCK_PROFILE_FILE"; then
        log_error "FAIL (Env Var): 'GFT_PROJECTS_HOME' not found." && ((checks_failed++))
    fi
    if ! grep -q 'export GFT_AWS_PROFILE="gft-devops"' "$MOCK_PROFILE_FILE"; then
        log_error "FAIL (Env Var): 'GFT_AWS_PROFILE' not found." && ((checks_failed++))
    fi
    if [ ! -d "$MOCK_HOME/gft_studio" ]; then
        log_error "FAIL (Env Var): Workspace directory was not created." && ((checks_failed++))
    fi

    # Restore HOME
    export HOME="$ORIGINAL_HOME"

    if [[ $checks_failed -ne 0 ]]; then
        echo "--- Raw Env Var Test Output ---"
        echo "$output"
        return 1
    fi
    log_success "Environment Variable Logic: PASSED"
}

test_vscode_extension_logic() {
    log_info "[TEST SUITE 4] Testing VS Code Extension Logic..."
    MOCK_CODE_INSTALLED_EXTS="ms-python.python"
    local output; output=$(install_vscode_extensions_for_role "devops-specialist" 2>&1)
    local checks_failed=0

    [[ "$output" != *"MOCK_code_install:hashicorp.terraform"* ]] && log_error "FAIL (VS Code): Global extension missing." && ((checks_failed++))
    [[ "$output" != *"MOCK_code_install:redhat.ansible"* ]] && log_error "FAIL (VS Code): Role extension missing." && ((checks_failed++))

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw VS Code Test Output ---" && echo "$output"; return 1; fi
    log_success "VS Code Extension Logic: PASSED"
}

test_performance_and_caching_logic() {
    log_info "[TEST SUITE 5] Testing Performance & Caching Logic..."
    local output; output=$(performance_and_caching 2>&1)
    local checks_failed=0

    [[ "$output" != *"MOCK_docker_CALLED_WITH: pull public.ecr.aws/docker/library/node:20"* ]] && log_error "FAIL (Caching): First image missing." && ((checks_failed++))
    [[ "$output" != *"MOCK_docker_CALLED_WITH: pull public.ecr.aws/docker/library/python:3.11"* ]] && log_error "FAIL (Caching): Second image missing." && ((checks_failed++))

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw Caching Test Output ---" && echo "$output"; return 1; fi
    log_success "Performance & Caching Logic: PASSED"
}

test_final_validation_logic() {
    log_info "[TEST SUITE 6] Testing Final Validation Logic..."
    local workspace; workspace=$(mktemp -d)
    mkdir -p "$workspace/gcs-devops-standards"
    export GFT_PROJECTS_HOME="$workspace"

    local mock_bin; mock_bin=$(mktemp -d)
    local original_path="$PATH"
    PATH="$mock_bin:$PATH"

    cat <<'EOF' > "$mock_bin/gft"
#!/usr/bin/env bash
echo "MOCK_gft_CALLED_WITH:$*"
EOF
    chmod +x "$mock_bin/gft"

    cat <<'EOF' > "$mock_bin/pre-commit"
#!/usr/bin/env bash
echo "MOCK_pre-commit_CALLED_WITH:$*"
EOF
    chmod +x "$mock_bin/pre-commit"

    local output; output=$(final_validation 2>&1)
    local checks_failed=0

    [[ "$output" != *"MOCK_gft_CALLED_WITH:config setup"* ]] && log_error "FAIL (Validation): gft not invoked." && ((checks_failed++))
    [[ "$output" != *"MOCK_pre-commit_CALLED_WITH:run --all-files"* ]] && log_error "FAIL (Validation): pre-commit not invoked." && ((checks_failed++))

    PATH="$original_path"
    rm -rf "$workspace" "$mock_bin"

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw Validation Test Output ---" && echo "$output"; return 1; fi
    log_success "Final Validation Logic: PASSED"
}

test_environment_variable_idempotency() {
    log_info "[TEST SUITE 4] Testing Environment Variable Idempotency..."
    local PROFILE_FILE; PROFILE_FILE=$(mktemp)
    trap "rm -f '$PROFILE_FILE'; trap - RETURN" RETURN

    configure_environment_variables "devops-specialist" "$PROFILE_FILE" >/dev/null
    configure_environment_variables "devops-specialist" "$PROFILE_FILE" >/dev/null

    local start_count end_count
    start_count=$(grep -c '# GENCRAFT ENVIRONMENT - START' "$PROFILE_FILE")
    end_count=$(grep -c '# GENCRAFT ENVIRONMENT - END' "$PROFILE_FILE")

    if [[ $start_count -ne 1 || $end_count -ne 1 ]]; then
        log_error "Environment block markers were duplicated."
        return 1
    fi

    local var
    for var in GFT_PROJECTS_HOME GFT_AWS_PROFILE GFT_DEFAULT_REGION; do
        local count
        count=$(grep -c "export $var=" "$PROFILE_FILE")
        if [[ $count -ne 1 ]]; then
            log_error "Variable '$var' expected once, found $count occurrences."
            return 1
        fi
    done

    log_success "Environment variable configuration is idempotent."
}

# ==============================================================================
# --- Test Runner ---
# ==============================================================================
main() {
    local mock_matrix_path="${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md"
    ROLE_MATRIX_YAML=$(sed -n '/```yaml/,/```/p' "$mock_matrix_path" | sed '1d;$d')
    export ROLE_MATRIX_YAML
    if [ -z "$ROLE_MATRIX_YAML" ]; then
        log_error "FATAL: Could not load YAML from mock file. Test setup failed." && exit 1
    fi

    local failed_suites=0
    test_tool_installation_logic || ((failed_suites++))
    test_repository_cloning_logic || ((failed_suites++))
    test_base_repository_injection_when_missing || ((failed_suites++))
    test_environment_variable_logic || ((failed_suites++))
    test_environment_variable_idempotency || ((failed_suites++))

    echo "-------------------------------------------"
    if [[ $failed_suites -ne 0 ]]; then
        log_error "🔴 $failed_suites TEST SUITE(S) FAILED." && exit 1
    else
        log_success "✅ ALL TEST SUITES PASSED." && exit 0
    fi
}

# --- Main Execution Block ---
main
