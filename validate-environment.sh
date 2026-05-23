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
set -euo pipefail

# --- Global Variables ---
# These are identical to the main onboarding script to ensure consistency
readonly GFT_SSOT_REPO="https://github.com/GenCr-ft/gcs-devops-standards.git"
readonly GFT_SSOT_PATH="/tmp/gft-ssot-validation" # Use a separate cache path
readonly ROLE_MATRIX_FILE="foundations/governance/GOV-004-role-tooling-matrix.md"
readonly TOOLING_SPECS_FILE="domains/tooling/standards/tool-002-technical-tooling-specifications.md"
readonly GFT_WORKSPACE="$HOME/gft_studio"
readonly GFT_SSOT_GEMOP_PATH="${GFT_SSOT_GEMOP_PATH:-${HOME}/gft_studio/gcs-plt-gemop}"

# Counters for the final report
declare -i PASS_COUNT=0
declare -i FAIL_COUNT=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helper Functions ---
# (A minimal set of helpers for this script)
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }
check_ok() { echo -e "  \033[1;32m[OK]\033[0m $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
check_fail() { echo -e "  \033[1;31m[FAIL]\033[0m $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

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

# Checks orchestration health: skill/agent symlinks and studio hooks registration
check_orchestration_health() {
    log_info "=== Orchestration Health Check ==="

    local gemop_path="${GFT_SSOT_GEMOP_PATH}"
    local skills_source="${gemop_path}/skills"
    local agents_source="${gemop_path}/agents"
    local claude_skills="${HOME}/.claude/skills"
    local claude_agents="${HOME}/.claude/agents"
    local settings_local="${HOME}/.claude/settings.local.json"

    # 1. Skill symlink integrity
    if [[ -d "$skills_source" ]]; then
        local total_skills missing_skills=0
        total_skills=$(find "$skills_source" -mindepth 1 -maxdepth 1 -type d | wc -l)
        for skill_dir in "${skills_source}"/*/; do
            local skill_name
            skill_name=$(basename "$skill_dir")
            if [[ ! -L "${claude_skills}/${skill_name}" ]]; then
                missing_skills=$((missing_skills + 1))
            fi
        done
        if [[ $missing_skills -eq 0 ]]; then
            check_ok "All ${total_skills} skill symlinks are present in ~/.claude/skills/"
        else
            check_fail "${missing_skills}/${total_skills} skill symlinks missing from ~/.claude/skills/. Run gft-onboarding.sh to repair."
        fi
    else
        check_fail "gemop skills source not found at ${skills_source}. Set GFT_SSOT_GEMOP_PATH or clone gcs-plt-gemop."
    fi

    # 2. Agent file symlinks
    if [[ -d "$agents_source" ]]; then
        local total_agents=0 missing_agents=0
        while IFS= read -r -d '' agent_file; do
            local agent_name
            agent_name=$(basename "$agent_file")
            if [[ "$agent_name" == "grader.md" ]]; then continue; fi
            total_agents=$((total_agents + 1))
            if [[ ! -L "${claude_agents}/${agent_name}" ]]; then
                missing_agents=$((missing_agents + 1))
            fi
        done < <(find "$agents_source" -maxdepth 1 -name "*.md" -print0)
        if [[ $missing_agents -eq 0 ]]; then
            check_ok "All ${total_agents} agent symlinks are present in ~/.claude/agents/"
        else
            check_fail "${missing_agents}/${total_agents} agent symlinks missing from ~/.claude/agents/. Run gft-onboarding.sh to repair."
        fi
    else
        check_fail "gemop agents source not found at ${agents_source}."
    fi

    # 3. Hook registration
    if [[ -f "$settings_local" ]] && python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    hooks = d.get('hooks', {})
    assert 'PreToolUse' in hooks and 'PostToolUse' in hooks
except Exception as e:
    sys.exit(1)
" "$settings_local" 2>/dev/null; then
        check_ok "Studio hooks registered in ~/.claude/settings.local.json"
    else
        check_fail "Studio hooks not registered. Run gft-onboarding.sh to register them."
    fi
}

# --- Orchestration Health Check ---
# Checks local filesystem only — no network, no interactive prompts.
# Uses GFT_SSOT_GEMOP_PATH env var (default: ${HOME}/gft_studio/gcs-plt-gemop).
check_orchestration_health() {
    local gemop_path="${GFT_SSOT_GEMOP_PATH:-${HOME}/gft_studio/gcs-plt-gemop}"
    local claude_skills_dir="${HOME}/.claude/skills"
    local claude_agents_dir="${HOME}/.claude/agents"
    local claude_settings="${HOME}/.claude/settings.local.json"

    log_info "Checking orchestration health against: $gemop_path"

    # 1. Verify skill symlinks
    if [[ -d "${gemop_path}/skills" ]]; then
        local skill_count=0
        local missing_count=0
        for src_skill in "${gemop_path}/skills"/*/; do
            [[ -d "$src_skill" ]] || continue
            local skill_name
            skill_name=$(basename "$src_skill")
            local link_target="${claude_skills_dir}/${skill_name}"
            if [[ -L "$link_target" ]]; then
                check_ok "Skill symlink present: $skill_name"
                skill_count=$((skill_count + 1))
            else
                check_fail "Skill symlink missing: ${claude_skills_dir}/${skill_name}"
                missing_count=$((missing_count + 1))
            fi
        done
        if [[ $skill_count -eq 0 && $missing_count -eq 0 ]]; then
            log_info "No skills found in $gemop_path/skills — nothing to validate."
        fi
    else
        check_fail "GEMOP skills directory not found: ${gemop_path}/skills"
    fi

    # 2. Verify agent symlinks
    if [[ -d "${gemop_path}/agents" ]]; then
        local agent_count=0
        local agent_missing=0
        for src_agent in "${gemop_path}/agents"/*.md; do
            [[ -f "$src_agent" ]] || continue
            local agent_name
            agent_name=$(basename "$src_agent")
            local link_target="${claude_agents_dir}/${agent_name}"
            if [[ -L "$link_target" ]]; then
                check_ok "Agent symlink present: $agent_name"
                agent_count=$((agent_count + 1))
            else
                check_fail "Agent symlink missing: ${claude_agents_dir}/${agent_name}"
                agent_missing=$((agent_missing + 1))
            fi
        done
        if [[ $agent_count -eq 0 && $agent_missing -eq 0 ]]; then
            log_info "No agent files found in $gemop_path/agents — nothing to validate."
        fi
    else
        check_fail "GEMOP agents directory not found: ${gemop_path}/agents"
    fi

    # 3. Verify hooks are registered in settings.local.json
    if [[ -f "$claude_settings" ]]; then
        if grep -q '"hooks"' "$claude_settings"; then
            check_ok "Hooks block present in settings.local.json"
        else
            check_fail "Hooks block missing from settings.local.json"
        fi
    else
        check_fail "settings.local.json not found at ${claude_settings}"
    fi
}

# --- Main Orchestration ---
main() {
    # Parse flags
    local ORCHESTRATION_ONLY=false
    for arg in "$@"; do
        case "$arg" in
            --orchestration) ORCHESTRATION_ONLY=true ;;
        esac
    done

    if $ORCHESTRATION_ONLY; then
        check_orchestration_health
        echo
        log_info "--- Validation Summary ---"
        log_info "Checks Passed: $PASS_COUNT"
        log_info "Checks Failed: $FAIL_COUNT"
        if [[ $FAIL_COUNT -eq 0 ]]; then
            log_success "Orchestration health: all checks passed."
        else
            log_error "Orchestration health: ${FAIL_COUNT} check(s) failed. Run gft-onboarding.sh to repair."
            exit 1
        fi
        return
    fi

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
    check_orchestration_health
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
main "$@"
