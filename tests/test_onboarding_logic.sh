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

# Hermetic isolation of HOME to prevent host state leakage
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
unset GFT_PROJECTS_HOME GFT_WORKSPACE GFT_ROLE
trap 'rm -rf "$TEST_HOME"' EXIT

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
get_ssot_tool_version() { case "$1" in nodejs) echo "20.18.0" ;; python) echo "3.11.5" ;; opentofu) echo "1.6.0" ;; *) echo "" ;; esac; }

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
    [[ "$output" != *"MOCK_install_node_CALLED_WITH:20.18.0"* ]] && log_error "FAIL: node-lts not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_binary_CALLED_WITH:opentofu 1.6.0"* ]] && log_error "FAIL: opentofu not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_python_CALLED_WITH:3.11.5"* ]] && log_error "FAIL: python not processed correctly." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_with_pkg_mgr_CALLED_FOR:shellcheck"* ]] && log_error "FAIL: shellcheck not processed." && ((checks_failed++))
    [[ "$output" != *"MOCK_install_with_pkg_mgr_CALLED_FOR:yq"* ]] && log_error "FAIL: yq not processed." && ((checks_failed++))

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw Tool Test Output ---" && echo "$output"; return 1; fi
    log_success "Tool Installation Logic: PASSED"
}

test_gft_install_deferred_until_clone() {
    log_info "[TEST SUITE 1b] Testing deferred gft installation before repo clone..."
    local tmp_home; tmp_home=$(mktemp -d)
    local tmp_workspace; tmp_workspace=$(mktemp -d)
    local original_home="$HOME"
    local original_workspace="${GFT_PROJECTS_HOME:-}"
    export HOME="$tmp_home"
    export GFT_PROJECTS_HOME="$tmp_workspace"

    local output; output=$(install_gft_cli 2>&1)
    local status=$?

    export HOME="$original_home"
    export GFT_PROJECTS_HOME="$original_workspace"
    rm -rf "$tmp_home" "$tmp_workspace"

    if [[ $status -ne 0 ]]; then
        log_error "FAIL (gft defer): install_gft_cli should return 0 when source is not cloned yet." && echo "$output" && return 1
    fi
    if [[ "$output" != *"deferring gft installation until repositories are cloned"* ]]; then
        log_error "FAIL (gft defer): expected deferred-install warning not found." && echo "$output" && return 1
    fi
    log_success "Deferred gft installation Logic: PASSED"
}

test_gft_install_delegates_to_gcs_plt_tools_onboard() {
    log_info "[TEST SUITE 1c] Testing delegated gft installation..."
    local tmp_home; tmp_home=$(mktemp -d)
    local tmp_workspace; tmp_workspace=$(mktemp -d)
    # gcs-plt-tools now lives in studio_home() (default $HOME/.gft-studio), not
    # the project workspace (ENG-ADR-088 §3 / WI-384b).
    local plt_root="$tmp_home/.gft-studio/gcs-plt-tools"
    local log_file="$tmp_workspace/onboard.called"
    local original_home="$HOME"
    local original_workspace="${GFT_PROJECTS_HOME:-}"
    local original_path="$PATH"

    mkdir -p "$plt_root"
    cat > "$plt_root/onboard.sh" <<'MOCK'
#!/usr/bin/env bash
echo "delegated-onboard" >> "__LOG_FILE__"
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/gft" <<'INNER'
#!/usr/bin/env bash
if [[ "${1:-}" == "version" ]]; then
    echo "1.2.3-delegated"
    exit 0
fi
echo "delegated gft $*"
INNER
chmod +x "$HOME/.local/bin/gft"
MOCK
    _sed_inplace "s|__LOG_FILE__|$log_file|" "$plt_root/onboard.sh"
    chmod +x "$plt_root/onboard.sh"

    export HOME="$tmp_home"
    export GFT_PROJECTS_HOME="$tmp_workspace"
    export PATH="/usr/bin:/bin"

    local output_file; output_file=$(mktemp)
    local output
    install_gft_cli >"$output_file" 2>&1
    local status=$?
    output=$(<"$output_file")
    local checks_failed=0

    [[ $status -ne 0 ]] && log_error "FAIL (gft delegate): install_gft_cli returned non-zero." && ((checks_failed++))
    [[ ! -f "$log_file" ]] && log_error "FAIL (gft delegate): delegated onboard.sh was not called." && ((checks_failed++))
    [[ "$output" != *"Delegating gft installation to $plt_root/onboard.sh"* ]] && log_error "FAIL (gft delegate): delegation log missing." && ((checks_failed++))
    [[ "$PATH" != *"$HOME/.local/bin"* ]] && log_error "FAIL (gft delegate): PATH not updated for current session." && ((checks_failed++))
    [[ ! -x "$HOME/.local/bin/gft" ]] && log_error "FAIL (gft delegate): wrapper binary not created." && ((checks_failed++))
    [[ "$("$HOME/.local/bin/gft" version)" != "1.2.3-delegated" ]] && log_error "FAIL (gft delegate): delegated gft version check failed." && ((checks_failed++))

    export HOME="$original_home"
    export GFT_PROJECTS_HOME="$original_workspace"
    export PATH="$original_path"
    rm -rf "$tmp_home" "$tmp_workspace" "$output_file"

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw Delegated gft Output ---" && echo "$output" && return 1; fi
    log_success "Delegated gft installation Logic: PASSED"
}

test_repository_cloning_logic() {
    log_info "[TEST SUITE 2] Testing Repository Cloning Logic..."
    local previous_mock="${MOCK_ROLE_REPO_OUTPUT:-}"
    MOCK_ROLE_REPO_OUTPUT=$'gencraft-iac\ngct-service-template-py'
    local output; output=$(clone_repositories_for_role "devops-specialist" 2>&1)
    MOCK_ROLE_REPO_OUTPUT="$previous_mock"
    if [[ "$output" != *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/gencraft-iac"* ]]; then
        log_error "FAIL (Repo): project repo 'gencraft-iac' was not cloned." && echo "$output" && return 1
    fi
    log_success "Repository Cloning Logic: PASSED"
}

# WI-384b: shared tooling installs exactly once into studio_home() via
# bootstrap_shared_tooling(); clone_repositories_for_role must NEVER clone it
# into the project workspace, even when a role matrix lists it (ENG-ADR-088 §3).
test_base_repository_injection_when_missing() {
    log_info "[TEST SUITE 2b] Testing shared-tooling is skipped in the workspace clone..."
    local previous_mock="${MOCK_ROLE_REPO_OUTPUT:-}"
    MOCK_ROLE_REPO_OUTPUT=$'gcs-plt-tools\ngcs-plt-gemop\ngcs-core-governance\ngct-service-template-py'
    local output; output=$(clone_repositories_for_role "devops-specialist" 2>&1)
    MOCK_ROLE_REPO_OUTPUT="$previous_mock"

    local checks_failed=0
    local st
    for st in gcs-plt-tools gcs-plt-gemop gcs-core-governance; do
        if [[ "$output" == *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/${st} "* ]]; then
            log_error "FAIL (Shared): '${st}' must NOT be cloned into the workspace." && ((checks_failed++))
        fi
    done
    if [[ "$output" != *"MOCK_gh_CALLED_WITH: repo clone GenCr-ft/gct-service-template-py"* ]]; then
        log_error "FAIL (Shared): genuine project repo was not cloned." && ((checks_failed++))
    fi
    if [[ "$output" != *"shared tooling installs once"* ]]; then
        log_error "FAIL (Shared): missing shared-tooling workspace-skip notice." && ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then echo "$output" && return 1; fi
    log_success "Shared-tooling workspace-skip Logic: PASSED"
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
    # A returning user keeps a project-local gcs-core-governance checkout;
    # final_validation prefers it (git repo) over the shared studio home.
    mkdir -p "$workspace/gcs-core-governance/.git"
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

    [[ "$output" != *"gft-cli is installed: MOCK_gft_CALLED_WITH:version"* ]] && log_error "FAIL (Validation): gft version check not reported." && ((checks_failed++))
    [[ "$output" != *"MOCK_pre-commit_CALLED_WITH:run --all-files"* ]] && log_error "FAIL (Validation): pre-commit not invoked." && ((checks_failed++))

    PATH="$original_path"
    rm -rf "$workspace" "$mock_bin"

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw Validation Test Output ---" && echo "$output"; return 1; fi
    log_success "Final Validation Logic: PASSED"
}

test_configure_gft_cli_bootstraps_cli_and_exports_env() {
    log_info "[TEST SUITE 6b] Testing configure_gft_cli bootstraps gft..."
    local tmp_home; tmp_home=$(mktemp -d)
    local tmp_workspace; tmp_workspace=$(mktemp -d)
    # gcs-plt-tools now lives in studio_home() (default $HOME/.gft-studio).
    local plt_root="$tmp_home/.gft-studio/gcs-plt-tools"
    local original_home="$HOME"
    local original_workspace="${GFT_PROJECTS_HOME:-}"
    local original_path="$PATH"

    mkdir -p "$plt_root"
    cat > "$plt_root/onboard.sh" <<'MOCK'
#!/usr/bin/env bash
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/gft" <<'INNER'
#!/usr/bin/env bash
if [[ "${1:-}" == "version" ]]; then
    echo "2.0.0-configured"
    exit 0
fi
echo "configured gft $*"
INNER
chmod +x "$HOME/.local/bin/gft"
MOCK
    chmod +x "$plt_root/onboard.sh"

    export HOME="$tmp_home"
    export GFT_PROJECTS_HOME="$tmp_workspace"
    export PATH="/usr/bin:/bin"

    local output_file; output_file=$(mktemp)
    local output
    configure_gft_cli >"$output_file" 2>&1
    output=$(<"$output_file")
    local profile_file="$HOME/.bashrc"
    local checks_failed=0

    [[ "$output" != *"Configuring gft CLI environment variables"* ]] && log_error "FAIL (configure gft): configure step did not run." && ((checks_failed++))
    [[ ! -x "$HOME/.local/bin/gft" ]] && log_error "FAIL (configure gft): gft not installed via delegated onboard." && ((checks_failed++))
    [[ "$PATH" != *"$HOME/.local/bin"* ]] && log_error "FAIL (configure gft): PATH not updated in current shell." && ((checks_failed++))
    [[ ! -f "$profile_file" ]] && log_error "FAIL (configure gft): shell profile not created." && ((checks_failed++))
    [[ ! -f "$profile_file" || "$(grep -c 'export GFT_PLT_ROOT=' "$profile_file")" -lt 1 ]] && log_error "FAIL (configure gft): GFT_PLT_ROOT not written to profile." && ((checks_failed++))
    [[ ! -f "$profile_file" || "$(grep -c 'export GFT_WORKSPACE=' "$profile_file")" -lt 1 ]] && log_error "FAIL (configure gft): GFT_WORKSPACE not written to profile." && ((checks_failed++))

    export HOME="$original_home"
    export GFT_PROJECTS_HOME="$original_workspace"
    export PATH="$original_path"
    rm -rf "$tmp_home" "$tmp_workspace" "$output_file"

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw configure_gft_cli Output ---" && echo "$output" && return 1; fi
    log_success "configure_gft_cli bootstrap Logic: PASSED"
}

test_configure_gft_cli_fails_when_owner_repo_missing_post_clone() {
    log_info "[TEST SUITE 6c] Testing configure_gft_cli is non-fatal without gcs-plt-tools after clone..."
    local tmp_home; tmp_home=$(mktemp -d)
    local tmp_workspace; tmp_workspace=$(mktemp -d)
    local original_home="$HOME"
    local original_workspace="${GFT_PROJECTS_HOME:-}"
    local original_path="$PATH"

    export HOME="$tmp_home"
    export GFT_PROJECTS_HOME="$tmp_workspace"
    export PATH="/usr/bin:/bin"

    local output_file; output_file=$(mktemp)
    local output
    configure_gft_cli >"$output_file" 2>&1
    local status=$?
    output=$(<"$output_file")
    local profile_file="$HOME/.bashrc"
    local checks_failed=0

    [[ $status -ne 0 ]] && log_error "FAIL (configure gft missing owner): configure_gft_cli should be non-fatal (return 0) when gcs-plt-tools is missing post-clone." && ((checks_failed++))
    [[ "$output" != *"Could not install the gft CLI now"* ]] && log_error "FAIL (configure gft missing owner): missing graceful gft-deferred warning." && ((checks_failed++))
    [[ -f "$profile_file" && "$(grep -c 'export GFT_PLT_ROOT=' "$profile_file" 2>/dev/null)" -gt 0 ]] && log_error "FAIL (configure gft missing owner): GFT_PLT_ROOT should not be written when gft is deferred." && ((checks_failed++))
    [[ -f "$profile_file" && "$(grep -c 'export GFT_WORKSPACE=' "$profile_file" 2>/dev/null)" -gt 0 ]] && log_error "FAIL (configure gft missing owner): GFT_WORKSPACE should not be written when gft is deferred." && ((checks_failed++))

    export HOME="$original_home"
    export GFT_PROJECTS_HOME="$original_workspace"
    export PATH="$original_path"
    rm -rf "$tmp_home" "$tmp_workspace" "$output_file"

    if [[ $checks_failed -ne 0 ]]; then echo "--- Raw configure_gft_cli missing-owner Output ---" && echo "$output" && return 1; fi
    log_success "configure_gft_cli missing-owner Logic: PASSED"
}

test_path_expansion_no_eval() {
    log_info "[TEST SUITE 7] Testing safe tilde/HOME path expansion (no eval)..."
    local checks_failed=0

    # Verify that eval is not used for path expansion in 03_configuration.sh
    local src_file="${PROJECT_ROOT}/includes/03_configuration.sh"
    if grep -q "eval evaluated_path" "$src_file"; then
        log_error "FAIL (Security): 'eval evaluated_path' still present in 03_configuration.sh — injection vector not removed."
        ((checks_failed++))
    fi

    # Verify tilde expansion works safely without eval
    local var_value='~/projects'
    local evaluated_path="${var_value//\~/$HOME}"
    if [[ "$evaluated_path" != "$HOME/projects" ]]; then
        log_error "FAIL (Expansion): tilde in '~/projects' not expanded. Got: $evaluated_path"
        ((checks_failed++))
    fi

    # Verify a $HOME-prefixed value works safely without eval
    local var_value2='"$HOME/workspace"'
    local stripped="${var_value2//\"/}"
    # shellcheck disable=SC2016
    if [[ "$stripped" == '$HOME'* ]]; then
        evaluated_path="${HOME}${stripped:5}"
    else
        evaluated_path="${stripped//\~/$HOME}"
    fi
    if [[ "$evaluated_path" != "$HOME/workspace" ]]; then
        log_error "FAIL (Expansion): '\$HOME/workspace' not expanded correctly. Got: $evaluated_path"
        ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "Safe path expansion: PASSED"
}

test_sed_inplace_portability() {
    log_info "[TEST SUITE 8] Testing _sed_inplace portability helper..."
    local checks_failed=0

    # Verify that _sed_inplace function is defined (not just bare sed -i calls)
    if ! declare -f _sed_inplace > /dev/null 2>&1; then
        log_error "FAIL (Portability): '_sed_inplace' helper function is not defined."
        ((checks_failed++))
    fi

    # Verify no bare 'sed -i' calls remain in 03_configuration.sh
    local src_file="${PROJECT_ROOT}/includes/03_configuration.sh"
    # Allow 'sed -i' only inside the _sed_inplace function definition itself
    local bare_sed_count
    bare_sed_count=$(grep -c "sed -i " "$src_file" || true)
    local helper_sed_count
    helper_sed_count=$(grep -c "_sed_inplace" "$src_file" || true)
    # bare_sed_count should equal 2 (the two lines inside _sed_inplace definition)
    # if there are more, there are un-wrapped sed -i calls
    if [[ "$bare_sed_count" -gt 2 ]]; then
        log_error "FAIL (Portability): Found $bare_sed_count 'sed -i' occurrences in 03_configuration.sh; expected at most 2 (inside helper). Un-wrapped calls remain."
        ((checks_failed++))
    fi

    # Functional test: _sed_inplace performs substitution on a temp file
    if declare -f _sed_inplace > /dev/null 2>&1; then
        local tmp_file; tmp_file=$(mktemp)
        trap "rm -f '$tmp_file'; trap - RETURN" RETURN
        printf 'Hello World\n' > "$tmp_file"
        _sed_inplace "s/World/Gencraft/" "$tmp_file"
        local result; result=$(< "$tmp_file")
        if [[ "$result" != "Hello Gencraft" ]]; then
            log_error "FAIL (Portability): _sed_inplace substitution produced '$result', expected 'Hello Gencraft'."
            ((checks_failed++))
        fi
    fi

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "sed inplace portability: PASSED"
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

test_validate_env_has_set_e() {
    log_info "[TEST SUITE 9] Testing validate-environment.sh has set -e..."
    local checks_failed=0
    local script="${PROJECT_ROOT}/validate-environment.sh"

    # Verify set -e or set -euo pipefail is present
    if ! grep -qE "^set -[a-z]*e[a-z]*( |$)|^set -euo pipefail" "$script"; then
        log_error "FAIL (Robustness): 'set -e' is not present in validate-environment.sh."
        ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "validate-environment.sh has set -e: PASSED"
}

test_headless_onboarding_non_interactive() {
    log_info "[TEST SUITE 10] Testing Headless Onboarding Non-Interactive Override..."
    local checks_failed=0

    # Test 1: select_user_role auto-selects GFT_ROLE
    local selected; selected=$(GFT_ROLE=programming select_user_role 2>&1)
    if [[ "$selected" != *"programming"* ]]; then
        log_error "FAIL: GFT_ROLE selection failed. Output: $selected"
        ((checks_failed++))
    fi

    # Test 2: confirm_action auto-approves when GFT_NON_INTERACTIVE=true
    if ! GFT_NON_INTERACTIVE=true confirm_action "Mock Question"; then
        log_error "FAIL: confirm_action did not auto-approve under GFT_NON_INTERACTIVE."
        ((checks_failed++))
    fi

    # Test 3: configure_git does not prompt under GFT_NON_INTERACTIVE=true
    local mock_git_out
    mock_git_out=$(GFT_NON_INTERACTIVE=true configure_git 2>&1)
    local git_name; git_name=$(git config --global user.name || echo "")
    if [[ -z "$git_name" ]]; then
        log_error "FAIL: Git name not set."
        ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "Headless Onboarding Non-Interactive: PASSED"
}

test_workspace_quickstart_contract() {
    log_info "[TEST SUITE 11] Testing Workspace Quickstart Contract..."
    local checks_failed=0
    local ws_parse_out; ws_parse_out=$(mktemp)
    local ws_parse_err; ws_parse_err=$(mktemp)
    local help_out;     help_out=$(mktemp)
    local help_err;     help_err=$(mktemp)
    trap "rm -f '$ws_parse_out' '$ws_parse_err' '$help_out' '$help_err'; trap - RETURN" RETURN

    for workspace in aethel gft-platform onboarding agent-ecosystem; do
        if ! parse_cli_args --quickstart --workspace "$workspace"; then
            log_error "FAIL: valid workspace '$workspace' was rejected."
            ((checks_failed++))
            continue
        fi

        if [[ "${GFT_QUICKSTART:-}" != "true" ]]; then
            log_error "FAIL: --quickstart did not set GFT_QUICKSTART=true for '$workspace'."
            ((checks_failed++))
        fi
        if [[ "${GFT_WORKSPACE:-}" != "$workspace" ]]; then
            log_error "FAIL: --workspace did not set GFT_WORKSPACE='$workspace'."
            ((checks_failed++))
        fi
        if [[ -z "${GFT_ROLE:-}" ]]; then
            log_error "FAIL: workspace '$workspace' did not resolve to a role."
            ((checks_failed++))
        fi

        unset GFT_QUICKSTART GFT_WORKSPACE GFT_ROLE GFT_NON_INTERACTIVE
    done

    if parse_cli_args --quickstart --workspace unknown >"$ws_parse_out" 2>"$ws_parse_err"; then
        log_error "FAIL: invalid workspace was accepted."
        ((checks_failed++))
    elif ! grep -q "Valid workspaces" "$ws_parse_err"; then
        log_error "FAIL: invalid workspace error did not list valid workspaces."
        ((checks_failed++))
    fi

    if ! parse_cli_args --quickstart --workspace=workspace-ops; then
        log_error "FAIL: --workspace=<id> form was rejected."
        ((checks_failed++))
    fi
    if [[ "${GFT_NON_INTERACTIVE:-}" != "true" ]]; then
        log_error "FAIL: quickstart did not enable non-interactive confirmations."
        ((checks_failed++))
    fi
    unset GFT_QUICKSTART GFT_WORKSPACE GFT_ROLE GFT_NON_INTERACTIVE

    if ! parse_cli_args --help >"$help_out" 2>"$help_err"; then
        log_error "FAIL: --help was rejected."
        ((checks_failed++))
    fi
    if [[ "${GFT_SHOW_HELP_ONLY:-}" != "true" ]]; then
        log_error "FAIL: --help did not set GFT_SHOW_HELP_ONLY=true."
        ((checks_failed++))
    fi
    if ! grep -q "Usage:" "$help_out"; then
        log_error "FAIL: --help did not print usage."
        ((checks_failed++))
    fi
    unset GFT_SHOW_HELP_ONLY

    if ! parse_cli_args --role devops-specialist; then
        log_error "FAIL: existing --role form was rejected."
        ((checks_failed++))
    fi
    if [[ "${GFT_ROLE:-}" != "devops-specialist" ]]; then
        log_error "FAIL: existing --role form did not set GFT_ROLE."
        ((checks_failed++))
    fi
    unset GFT_ROLE

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "Workspace Quickstart Contract: PASSED"
}

test_preflight_connectivity_hard_fail() {
    log_info "[TEST SUITE] Preflight: connectivity hard fail exits 1..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity() { return 1; }

    local output exit_code
    output=$(run_preflight 2>&1) || exit_code=$?

    if [[ "${exit_code:-0}" -ne 1 ]]; then
        log_error "FAIL: run_preflight should exit 1 when offline. Got: ${exit_code:-0}"
        return 1
    fi
    if [[ "$output" != *"No internet connectivity"* ]]; then
        log_error "FAIL: expected 'No internet connectivity' message. Got: $output"
        return 1
    fi

    log_success "Preflight connectivity hard fail: PASSED"
}

test_preflight_table_all_pass() {
    log_info "[TEST SUITE] Preflight: table renders with all checks passing..."
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
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "FAIL: all-pass preflight should exit 0. Got: $exit_code. Output: $output"
        return 1
    fi
    if [[ "$output" != *"All checks passed"* ]]; then
        log_error "FAIL: expected 'All checks passed' in output. Got: $output"
        return 1
    fi
    if [[ "$output" == *"MISSING"* ]]; then
        log_error "FAIL: no MISSING rows expected when all tools present. Got: $output"
        return 1
    fi

    log_success "Preflight table all-pass: PASSED"
}

test_preflight_table_mixed() {
    log_info "[TEST SUITE] Preflight: table renders with missing gh row..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command() {
        case "$1" in
            gh) return 1 ;;
            *)  return 0 ;;
        esac
    }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    # Stub resolve so the test only exercises the render path
    _pf_resolve_issues() { return 0; }

    local output
    output=$(run_preflight 2>&1)

    if [[ "$output" != *"gh (GitHub CLI)"* ]]; then
        log_error "FAIL: table should show 'gh (GitHub CLI)' row. Got: $output"
        return 1
    fi
    if [[ "$output" != *"MISSING"* ]]; then
        log_error "FAIL: expected MISSING status in output. Got: $output"
        return 1
    fi
    if [[ "$output" != *"item(s) need attention"* ]]; then
        log_error "FAIL: expected attention summary. Got: $output"
        return 1
    fi

    log_success "Preflight table mixed: PASSED"
}

test_preflight_install_prompt_yes() {
    log_info "[TEST SUITE] Preflight: install prompt Y triggers install..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    local _install_flag; _install_flag=$(mktemp)
    _pf_check_connectivity()   { return 0; }
    _pf_has_command() { [[ "$1" == "gh" ]] && return 1 || return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    export _PREFLIGHT_INSTALL_FLAG="$_install_flag"
    install_with_package_manager() { echo "$1" > "${_PREFLIGHT_INSTALL_FLAG}"; return 0; }
    GFT_WORKSPACE=""
    GFT_NON_INTERACTIVE="true"

    local output
    output=$(run_preflight 2>&1)
    local exit_code=$?

    unset GFT_NON_INTERACTIVE
    local _install_called
    _install_called=$(cat "$_install_flag" 2>/dev/null || true)
    rm -f "$_install_flag"
    unset _PREFLIGHT_INSTALL_FLAG

    if [[ $exit_code -ne 0 ]]; then
        log_error "FAIL: exit code should be 0 after Y install. Got: $exit_code. Output: $output"
        return 1
    fi
    if [[ "$_install_called" != "gh" ]]; then
        log_error "FAIL: install_with_package_manager should be called with 'gh'. Got: '${_install_called}'"
        return 1
    fi

    log_success "Preflight install prompt Y: PASSED"
}

test_preflight_install_prompt_no() {
    log_info "[TEST SUITE] Preflight: install prompt N marks SKIPPED and exits 1..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command() { [[ "$1" == "gh" ]] && return 1 || return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    confirm_action() { return 1; }

    local output exit_code
    output=$(run_preflight 2>&1) || exit_code=$?

    if [[ "${exit_code:-0}" -ne 1 ]]; then
        log_error "FAIL: should exit 1 after declining install. Got: ${exit_code:-0}"
        return 1
    fi
    if [[ "$output" != *"SKIPPED"* ]]; then
        log_error "FAIL: expected SKIPPED in output. Got: $output"
        return 1
    fi
    if [[ "$output" != *"required checks failed"* ]]; then
        log_error "FAIL: expected 'required checks failed' summary. Got: $output"
        return 1
    fi

    log_success "Preflight install prompt N: PASSED"
}

test_preflight_gh_auth_prompts_login() {
    log_info "[TEST SUITE] Preflight: unauth gh prompts gh auth login..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    local _flag_file; _flag_file=$(mktemp)
    _pf_check_connectivity()   { return 0; }
    _pf_has_command()          { return 0; }
    _pf_check_gh_auth()        { return 1; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    confirm_action()   { return 0; }
    export _PREFLIGHT_AUTH_FLAG="$_flag_file"
    gh() {
        if [[ "$1 $2" == "auth login" ]]; then
            touch "${_PREFLIGHT_AUTH_FLAG}"
            _pf_check_gh_auth() { return 0; }
            return 0
        fi
        command gh "$@" 2>/dev/null || true
    }

    local output
    output=$(run_preflight 2>&1)
    local exit_code=$?

    unset _PREFLIGHT_AUTH_FLAG
    local _gh_login_called=false
    [[ -f "$_flag_file" ]] && _gh_login_called=true
    rm -f "$_flag_file"

    if [[ $exit_code -ne 0 ]]; then
        log_error "FAIL: should exit 0 after successful auth. Got: $exit_code. $output"
        return 1
    fi
    if [[ "$_gh_login_called" != "true" ]]; then
        log_error "FAIL: gh auth login was not called."
        return 1
    fi

    log_success "Preflight gh auth prompts login: PASSED"
}

test_preflight_workspace_aethel_checks_node_docker() {
    log_info "[TEST SUITE] Preflight: aethel workspace adds node and docker rows..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command()          { return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    _pf_cmd_version()          { echo "22.1.0"; }
    GFT_WORKSPACE="aethel"

    local output
    output=$(run_preflight 2>&1)

    if [[ "$output" != *"node >= 20"* ]]; then
        log_error "FAIL: expected 'node >= 20' row for aethel. Got: $output"
        return 1
    fi
    if [[ "$output" != *"docker"* ]]; then
        log_error "FAIL: expected 'docker' row for aethel. Got: $output"
        return 1
    fi

    log_success "Preflight workspace aethel node+docker: PASSED"
}

test_preflight_no_workspace_no_extra_checks() {
    log_info "[TEST SUITE] Preflight: no workspace omits workspace-specific rows..."
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

    if [[ "$output" == *"node >= 20"* ]]; then
        log_error "FAIL: 'node >= 20' should be absent when no workspace. Got: $output"
        return 1
    fi
    if [[ "$output" == *"docker"* ]]; then
        log_error "FAIL: 'docker' should be absent when no workspace. Got: $output"
        return 1
    fi

    log_success "Preflight no workspace no extra checks: PASSED"
}

test_preflight_critical_fail_exits_one() {
    log_info "[TEST SUITE] Preflight: unresolved critical failure exits 1 with summary..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command() { [[ "$1" == "gh" ]] && return 1 || return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "50"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    confirm_action() { return 1; }

    local output exit_code
    output=$(run_preflight 2>&1) || exit_code=$?

    if [[ "${exit_code:-0}" -ne 1 ]]; then
        log_error "FAIL: should exit 1 with unresolved critical check. Got: ${exit_code:-0}"
        return 1
    fi
    if [[ "$output" != *"required checks failed"* ]]; then
        log_error "FAIL: expected 'required checks failed' summary. Got: $output"
        return 1
    fi

    log_success "Preflight critical fail exits 1: PASSED"
}

test_preflight_disk_warn_non_blocking() {
    log_info "[TEST SUITE] Preflight: low disk triggers warn, user can continue..."
    source "${PROJECT_ROOT}/includes/07_preflight.sh"

    _pf_check_connectivity()   { return 0; }
    _pf_has_command()          { return 0; }
    _pf_check_gh_auth()        { return 0; }
    _pf_check_org_membership() { return 0; }
    _pf_free_disk_gb()         { echo "1"; }
    _pf_git_user_name()        { echo "Dev"; }
    _pf_git_user_email()       { echo "dev@example.com"; }
    GFT_WORKSPACE=""
    confirm_action() { return 0; }

    local output
    output=$(run_preflight 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "FAIL: low disk + Y should exit 0. Got: $exit_code. $output"
        return 1
    fi
    if [[ "$output" != *"LOW MEM"* ]]; then
        log_error "FAIL: expected LOW MEM in table. Got: $output"
        return 1
    fi

    log_success "Preflight disk warn non-blocking: PASSED"
}

test_quickstart_documentation_contract() {
    log_info "[TEST SUITE 12] Testing Quickstart Documentation Contract..."
    local checks_failed=0
    local readme_path="${TEST_SCRIPT_PATH}/../README.md"

    if grep -q "gcd-onboarding-scripts/archive/refs/heads/main.tar.gz" "$readme_path"; then
        log_error "FAIL: README quickstart still references archive download — must use git clone."
        ((checks_failed++))
    fi

    if ! grep -q "git clone https://github.com/GenCr-ft/gcd-onboarding-scripts.git" "$readme_path"; then
        log_error "FAIL: README quickstart does not show git clone installation path."
        ((checks_failed++))
    fi

    if grep -q "Invoke-WebRequest" "$readme_path"; then
        log_error "FAIL: README Windows section still references Invoke-WebRequest — must use git clone."
        ((checks_failed++))
    fi

    if ! grep -q "Set-ExecutionPolicy" "$readme_path"; then
        log_error "FAIL: README Windows section is missing Set-ExecutionPolicy bypass — required for PS5.1 compatibility."
        ((checks_failed++))
    fi

    if grep -q "raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/gft-onboarding.sh" "$readme_path"; then
        log_error "FAIL: README still advertises the non-runnable standalone gft-onboarding.sh download."
        ((checks_failed++))
    fi

    if grep -q "gft-onboarding.sh.sha256" "$readme_path"; then
        log_error "FAIL: README references a checksum artifact that is not shipped in this repo."
        ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "Quickstart Documentation Contract: PASSED"
}

test_role_tools_mixed_yaml_format() {
    log_info "[TEST SUITE 1e] Testing get_role_tools.py with mixed dict/string tool format..."
    local mixed_yaml
    mixed_yaml=$(cat <<'YAML'
roles:
  - name: common-base
    tools:
      - name: git
      - name: github-cli
  - name: child-role
    inherits: common-base
    tools: ["opentofu", "kubectl"]
YAML
)
    local output exit_code
    output=$(printf '%s' "$mixed_yaml" | command python3 "${PROJECT_ROOT}/includes/get_role_tools.py" "child-role" 2>&1)
    exit_code=$?

    local checks_failed=0
    [[ $exit_code -ne 0 ]] && log_error "FAIL: get_role_tools.py exited $exit_code. Output: $output" && ((checks_failed++))
    [[ "$output" != *"git"* ]] && log_error "FAIL: 'git' (dict-format parent) missing from output" && ((checks_failed++))
    [[ "$output" != *"github-cli"* ]] && log_error "FAIL: 'github-cli' (dict-format parent) missing from output" && ((checks_failed++))
    [[ "$output" != *"opentofu"* ]] && log_error "FAIL: 'opentofu' (string-format child) missing from output" && ((checks_failed++))
    [[ "$output" != *"kubectl"* ]] && log_error "FAIL: 'kubectl' (string-format child) missing from output" && ((checks_failed++))

    if [[ $checks_failed -ne 0 ]]; then echo "--- Output ---" && echo "$output"; return 1; fi
    log_success "Role tools mixed YAML format: PASSED"
}

test_env_var_warns_when_ssot_empty() {
    log_info "[TEST SUITE 3c] Testing env-var WARN when SSoT file has no role blocks..."
    local mock_ssot mock_home mock_profile
    mock_ssot=$(mktemp -d)
    mock_home=$(mktemp -d)
    mock_profile=$(mktemp)
    trap "rm -rf '$mock_ssot' '$mock_home'; rm -f '$mock_profile'; trap - RETURN" RETURN

    mkdir -p "${mock_ssot}/tooling"
    echo "# Policy document only — no role sections" > "${mock_ssot}/tooling/ENG-STAN-002.environment-variable-standard.md"

    local orig_ssot="$GFT_SSOT_PATH" orig_home="$HOME"
    export GFT_SSOT_PATH="$mock_ssot"
    export HOME="$mock_home"

    local output
    output=$(configure_environment_variables "devops-specialist" "$mock_profile" 2>&1)

    export GFT_SSOT_PATH="$orig_ssot"
    export HOME="$orig_home"

    if [[ "$output" != *"WARN"* ]]; then
        log_error "FAIL: Expected WARN when SSoT env vars file has no role blocks. Got: $output"
        return 1
    fi
    log_success "Env var WARN when SSoT empty: PASSED"
}

test_win_bootstrap_filename_consistency() {
    log_info "[TEST SUITE] Win Bootstrap: PS1 filename matches bash entry point..."
    local checks_failed=0

    local ps1_file="${PROJECT_ROOT}/onboarding-win.ps1"
    local bash_entry="${PROJECT_ROOT}/gft-onboarding.sh"

    # The bash entry point must exist on disk
    if [[ ! -f "$bash_entry" ]]; then
        log_error "FAIL: bash entry point not found at $bash_entry"
        ((checks_failed++))
    fi

    # Extract the value assigned to $BashOnboardingScriptName in the PS1
    local assigned_name
    assigned_name=$(grep -m1 'BashOnboardingScriptName\s*=' "$ps1_file" \
        | sed 's/.*=\s*"\(.*\)".*/\1/')

    if [[ -z "$assigned_name" ]]; then
        log_error "FAIL: could not extract BashOnboardingScriptName from $ps1_file"
        ((checks_failed++))
    elif [[ "$assigned_name" != "gft-onboarding.sh" ]]; then
        log_error "FAIL: BashOnboardingScriptName='$assigned_name' — expected 'gft-onboarding.sh'"
        ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "Win Bootstrap Filename Consistency: PASSED"
}

test_main_orchestration_smoke() {
    log_info "[TEST SUITE] Main Orchestration Smoke: isolated HOME, all network stubbed..."
    local smoke_home; smoke_home=$(mktemp -d)
    local smoke_ws; smoke_ws=$(mktemp -d)
    local smoke_out; smoke_out=$(mktemp)
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
        configure_environment_variables()    { :; }
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
    if [[ $exit_code -ne 0 ]]; then
        log_error "FAIL: main() smoke test exited $exit_code (expected 0)"
        cat "$smoke_out" >&2
        return 1
    fi
    log_success "Main Orchestration Smoke: PASSED"
}

test_auxiliary_scripts_windows_invocation_uses_clone() {
    log_info "[TEST SUITE 13] Testing auxiliary-scripts.md Windows invocation uses clone..."
    local aux_path="${TEST_SCRIPT_PATH}/../docs/auxiliary-scripts.md"
    local checks_failed=0

    if ! grep -q "git clone https://github.com/GenCr-ft/gcd-onboarding-scripts.git" "$aux_path"; then
        log_error "FAIL: docs/auxiliary-scripts.md does not show git clone installation path."
        ((checks_failed++))
    fi

    if grep -q "Invoke-WebRequest" "$aux_path"; then
        log_error "FAIL: docs/auxiliary-scripts.md still references Invoke-WebRequest — must use git clone."
        ((checks_failed++))
    fi

    if grep -q "\.sha256" "$aux_path"; then
        log_error "FAIL: docs/auxiliary-scripts.md references .sha256 checksum artifacts that are not shipped."
        ((checks_failed++))
    fi

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "Auxiliary Scripts Windows Invocation Clone: PASSED"
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
    test_gft_install_deferred_until_clone || ((failed_suites++))
    test_gft_install_delegates_to_gcs_plt_tools_onboard || ((failed_suites++))
    test_role_tools_mixed_yaml_format || ((failed_suites++))
    test_repository_cloning_logic || ((failed_suites++))
    test_base_repository_injection_when_missing || ((failed_suites++))
    test_environment_variable_logic || ((failed_suites++))
    test_environment_variable_idempotency || ((failed_suites++))
    test_env_var_warns_when_ssot_empty || ((failed_suites++))
    test_vscode_extension_logic || ((failed_suites++))
    test_performance_and_caching_logic || ((failed_suites++))
    test_final_validation_logic || ((failed_suites++))
    test_configure_gft_cli_bootstraps_cli_and_exports_env || ((failed_suites++))
    test_configure_gft_cli_fails_when_owner_repo_missing_post_clone || ((failed_suites++))
    test_path_expansion_no_eval || ((failed_suites++))
    test_sed_inplace_portability || ((failed_suites++))
    test_validate_env_has_set_e || ((failed_suites++))
    test_headless_onboarding_non_interactive || ((failed_suites++))
    test_workspace_quickstart_contract || ((failed_suites++))
    test_quickstart_documentation_contract || ((failed_suites++))
    test_preflight_connectivity_hard_fail              || ((failed_suites++))
    test_preflight_table_all_pass                      || ((failed_suites++))
    test_preflight_table_mixed                         || ((failed_suites++))
    test_preflight_install_prompt_yes                  || ((failed_suites++))
    test_preflight_install_prompt_no                   || ((failed_suites++))
    test_preflight_gh_auth_prompts_login               || ((failed_suites++))
    test_preflight_workspace_aethel_checks_node_docker || ((failed_suites++))
    test_preflight_no_workspace_no_extra_checks        || ((failed_suites++))
    test_preflight_critical_fail_exits_one             || ((failed_suites++))
    test_preflight_disk_warn_non_blocking              || ((failed_suites++))
    test_win_bootstrap_filename_consistency            || ((failed_suites++))
    test_auxiliary_scripts_windows_invocation_uses_clone || ((failed_suites++))
    test_main_orchestration_smoke                      || ((failed_suites++))

    echo "-------------------------------------------"
    if [[ $failed_suites -ne 0 ]]; then
        log_error "🔴 $failed_suites TEST SUITE(S) FAILED." && exit 1
    else
        log_success "✅ ALL TEST SUITES PASSED." && exit 0
    fi
}

# --- Main Execution Block ---
main
