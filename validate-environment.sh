#!/usr/bin/env bash

# ==============================================================================
# GenCr@t Studio - Environment Validation Script V2
#
# Version: 2.0.0
#
# This script validates the local environment against the standards defined
# in the gcs-devops-standards repository for a specific role.
# It is designed to be run at any time to check for compliance.
# ==============================================================================

# --- Script Configuration and Robustness ---
set -u
set -o pipefail

# --- Global Variables ---
# These are identical to the main onboarding script to ensure consistency
readonly GFT_SSOT_REPO="https://github.com/GenCr-ft/gcs-devops-standards.git"
readonly GFT_SSOT_PATH="/tmp/gft-ssot-validation" # Use a separate cache path
readonly ROLE_MATRIX_FILE="foundations/governance/GOV-004-role-tooling-matrix.md"
readonly TOOLING_SPECS_FILE="domains/tooling/standards/tool-002-technical-tooling-specifications.md"
readonly GFT_WORKSPACE="$HOME/gft_studio"

# Counters for the final report
declare -i PASS_COUNT=0
declare -i FAIL_COUNT=0

# --- Helper Functions ---
# (A minimal set of helpers for this script)
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
check_ok() { echo -e "  \033[1;32m[OK]\033[0m $1"; ((PASS_COUNT++)); }
check_fail() { echo -e "  \033[1;31m[FAIL]\033[0m $1"; ((FAIL_COUNT++)); }

# Extracts the YAML data block from a given SSoT markdown file.
# $1: Path to the markdown file
get_yaml_from_ssot() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        log_error "SSoT file not found: $file_path"
        exit 1
    fi
    # Using double quotes to satisfy shellcheck SC2016, even though
    # no variable expansion is needed here. It's cleaner.
    sed -n "/\`\`\`yaml/,/\`\`\`/p" "$file_path" | sed '1d;$d'
}

# --- Validation Functions ---

# Checks a specific tool's presence and version
validate_tool() {
    local tool_name="$1"

    local tool_spec
    tool_spec=$(echo "$TOOLING_SPECS_YAML" | yq ".tools[] | select(.name == \"$tool_name\")")
    local package version method
    package=$(echo "$tool_spec" | yq -r '.package')
    version=$(echo "$tool_spec" | yq -r '.version')
    method=$(echo "$tool_spec" | yq -r '.method')

    log_info "Validating: $package (v$version)..."

    if [[ "$method" == "manual" ]]; then
        check_ok "$package is marked for manual install. Assuming it is present."
        return
    fi

    local cmd_name
    cmd_name=$(echo "$tool_spec" | yq -r '.name' | cut -d'-' -f1) # Simple logic to get command name e.g. node-lts -> node

    if ! command -v "$cmd_name" &> /dev/null; then
        check_fail "'$cmd_name' command not found."
        return
    fi

    # Add more specific version checks here if needed
    # For now, we check for presence
    check_ok "'$cmd_name' is installed."
}

# Checks all tools for a given role
validate_tools_for_role() {
    local role_name="$1"
    local python_helper_script="${SCRIPT_DIR}/includes/get_role_tools.py"
    if [ ! -f "$python_helper_script" ]; then
        log_error "FATAL: Python helper for tools not found at $python_helper_script"
        return 1
    fi
    mapfile -t required_tools < <(echo "$ROLE_MATRIX_YAML" | python3 "$python_helper_script" "$role_name")

    if [[ ${#required_tools[@]} -gt 0 ]]; then
      for tool in "${required_tools[@]}"; do
          validate_tool "$tool"
      done
    fi
}

# Checks for required repositories
validate_repos_for_role() {
    local role_name="$1"
    local python_helper_script="${SCRIPT_DIR}/includes/get_role_repos.py"
    if [ ! -f "$python_helper_script" ]; then
        log_error "FATAL: Python helper for repos not found at $python_helper_script"
        return 1
    fi
    mapfile -t required_repos < <(echo "$ROLE_MATRIX_YAML" | python3 "$python_helper_script" "$role_name")

    log_info "Validating cloned repositories in $GFT_WORKSPACE..."
    if [[ ${#required_repos[@]} -gt 0 ]]; then
      for repo in "${required_repos[@]}"; do
          if [ -d "$GFT_WORKSPACE/$repo" ]; then
              check_ok "Repository '$repo' exists."
          else
              check_fail "Repository '$repo' is missing."
          fi
      done
    fi
}

# Checks for global git configuration
validate_git_config() {
    log_info "Validating Git global configuration..."
    if [[ -n "$(git config --global user.name)" ]]; then
        check_ok "Git user.name is set."
    else
        check_fail "Git user.name is not set. Run 'git config --global user.name \"Your Name\"'."
    fi
    if [[ -n "$(git config --global user.email)" ]]; then
        check_ok "Git user.email is set."
    else
        check_fail "Git user.email is not set. Run 'git config --global user.email \"you@example.com\"'."
    fi
    local hooks_path
    hooks_path=$(git config --global core.hooksPath)
    if [[ "$hooks_path" == "$HOME/.gft-git-hooks" ]]; then
        check_ok "Global Git hooks path is correctly set."
    else
        check_fail "Global Git hooks path is not correctly set."
    fi
}


# --- Main Orchestration ---
main() {
    log_info "Starting GenCr@t Environment Validator..."

    # Clone/update SSoT
    if [ -d "$GFT_SSOT_PATH" ]; then (cd "$GFT_SSOT_PATH" && git pull); else git clone --depth 1 "$GFT_SSOT_REPO" "$GFT_SSOT_PATH"; fi

    # Load SSoT data
    ROLE_MATRIX_YAML=$(get_yaml_from_ssot "$GFT_SSOT_PATH/$ROLE_MATRIX_FILE")
    TOOLING_SPECS_YAML=$(get_yaml_from_ssot "$GFT_SSOT_PATH/$TOOLING_SPECS_FILE")

    # Select role
    mapfile -t role_options < <(echo "$ROLE_MATRIX_YAML" | yq -r '.roles[] | select(.name != "common-base") | .name + ": " + .description')
    log_info "Please select the role to validate your environment against:"
    local selected_role_name
    select role_choice in "${role_options[@]}"; do
        if [[ -n "$role_choice" ]]; then selected_role_name=$(echo "$role_choice" | cut -d':' -f1); break; fi
    done

    echo # Newline for readability
    log_info "--- Starting Validation for role: $selected_role_name ---"

    # Run all validation functions
    validate_tools_for_role "$selected_role_name"
    validate_repos_for_role "$selected_role_name"
    validate_git_config
    # Add more validation calls here (e.g., VS Code extensions)

    # --- Final Report ---
    echo
    log_info "--- Validation Summary ---"
    log_info "Checks Passed: $PASS_COUNT"
    log_info "Checks Failed: $FAIL_COUNT"

    if [[ $FAIL_COUNT -eq 0 ]]; then
        log_success "Your environment is compliant with the standards for the '$selected_role_name' role."
    else
        log_error "Your environment has issues. Please review the [FAIL] messages above."
    fi
    log_info "--------------------------"
}

# --- Script Execution ---
main
