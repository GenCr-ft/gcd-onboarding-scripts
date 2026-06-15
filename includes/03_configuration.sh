#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_CONFIGURATION_03
# Title: Onboarding Script - Environment Configuration
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-09
# Last Modified Date: 2025-06-26
# Version: 2.2.0
#
# Description:
#   This script handles the post-installation configuration of the developer's
#   environment. This includes setting up Git identity, SSH keys, VS Code
#   extensions, and cloning required studio repositories based on the user's role.
#
# Usage:
#   This file is sourced by gft-onboarding.sh.
#
# Dependencies:
#   Functions from 01_helpers.sh.
#   External commands: git, ssh-keygen, gh, code.

# Cross-platform sed in-place helper.
# 'sed -i' requires an empty-string backup extension on macOS but not on Linux.
# Usage: _sed_inplace "s/old/new/" file
_sed_inplace() {
    if [[ "${GFT_OS:-linux}" == "darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Configures global Git user name and email
configure_git() {
    log_info "Configuring Git..."

    local current_name
    current_name=$(git config --global user.name || echo "")
    if [[ -z "$current_name" ]]; then
        if [[ "${GFT_NON_INTERACTIVE:-}" == "true" ]]; then
            git config --global user.name "Gencraft Developer"
        else
            read -r -p "Enter your full name for Git commits: " user_name
            git config --global user.name "$user_name"
        fi
    else
        log_info "Git user.name is already set to: $current_name"
    fi

    local current_email
    current_email=$(git config --global user.email || echo "")
    if [[ -z "$current_email" ]]; then
        if [[ "${GFT_NON_INTERACTIVE:-}" == "true" ]]; then
            git config --global user.email "dev@gencraft.studio"
        else
            read -r -p "Enter your email for Git commits: " user_email
            git config --global user.email "$user_email"
        fi
    else
        log_info "Git user.email is already set to: $current_email"
    fi

    # Set other global configs from SSoT
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    log_success "Git has been configured."
}

# Sets up an SSH key and adds it to GitHub
setup_ssh_key() {
    log_info "Checking for SSH key..."
    local ssh_key_path="$HOME/.ssh/id_ed25519"
    if [ ! -f "$ssh_key_path" ]; then
        log_warn "No SSH key found. Let's create one."
        local git_email
        git_email=$(git config --global user.email 2>/dev/null || echo "")
        mkdir -p "$(dirname "$ssh_key_path")"
        ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key_path" -N ""
        log_success "New SSH key created at $ssh_key_path"
    else
        log_info "Existing SSH key found."
    fi

    if confirm_action "Add this SSH key to your GitHub account automatically?"; then
        if ! command -v gh &> /dev/null; then
            log_error "GitHub CLI 'gh' not found. Cannot add SSH key automatically."
            return 1
        fi
        log_info "Adding SSH key to GitHub..."
        gh ssh-key add "$ssh_key_path.pub" --title "Onboarding-$(hostname)"
        log_success "SSH key added to GitHub account."
    fi
}

# Installs all VS Code extensions required for a given role
install_vscode_extensions_for_role() {
    local role_name="$1"
    if ! command -v code &> /dev/null; then
        log_warn "VS Code 'code' command not found in PATH. Skipping extension installation."
        return
    fi

    if [ -z "${GFT_SSOT_PATH:-}" ]; then
        log_warn "GFT_SSOT_PATH is not defined; cannot load VS Code recommendations."
        return
    fi

    local python_helper_script="${SCRIPT_DIR}/includes/get_vscode_extensions.py"
    if [ ! -f "$python_helper_script" ]; then
        log_error "FATAL: VS Code helper not found at $python_helper_script"
        return 1
    fi

    if [ ! -f "${GFT_SSOT_PATH}/tooling/VSCODE_RECOMMENDATIONS.md" ]; then
        log_warn "VS Code recommendations file not found in SSoT."
        return
    fi

    log_info "Fetching required VS Code extensions for role: $role_name"
    local required_extensions
    mapfile -t required_extensions < <(python3 "$python_helper_script" "$role_name" | sort -u)

    if [[ ${#required_extensions[@]} -eq 0 ]]; then
        log_info "No specific extensions for this role."
        return
    fi

    log_info "Installing ${#required_extensions[@]} VS Code extensions..."
    local installed_list
    installed_list=$(code --list-extensions)
    for ext_id in "${required_extensions[@]}"; do
        if grep -qiw "$ext_id" <<<"$installed_list"; then
            log_info "Extension '$ext_id' is already installed."
        else
            log_info "Installing extension: $ext_id"
            code --install-extension "$ext_id"
        fi
    done
    log_success "VS Code extension setup complete."
}

# Clones all repositories required for a given role by calling the Python helper.
clone_repositories_for_role() {
    local role_name="$1"


    if [ -z "${ROLE_MATRIX_YAML:-}" ]; then
        log_warn "ROLE_MATRIX_YAML not set, attempting to load SSoT configuration..."
        load_ssot_configuration
    fi

    log_info "Cloning required repositories for role: $role_name"

    local gft_workspace="${GFT_PROJECTS_HOME:-$HOME/gft_studio}"
    mkdir -p "$gft_workspace"

    local -a base_repos=(
        "gcs-core-governance"
        "gcs-core-governance"
    )

    local python_helper_script="${SCRIPT_DIR}/includes/get_role_repos.py"
    if [ ! -f "$python_helper_script" ]; then
        log_error "FATAL: Python helper for repos not found at $python_helper_script"
        return 1
    fi

    mapfile -t required_repos < <(echo "$ROLE_MATRIX_YAML" | python3 "$python_helper_script" "$role_name")
    local -a workspace_repos=()
    if [[ -n "${GFT_WORKSPACE:-}" ]]; then
        log_info "Adding repositories for workspace quickstart: $GFT_WORKSPACE"
        mapfile -t workspace_repos < <(workspace_repositories "$GFT_WORKSPACE")
    fi

    local -a merged_repos=()
    declare -A seen_repo
    for repo_name in "${required_repos[@]}" "${workspace_repos[@]}" "${base_repos[@]}"; do
        if [[ -z "$repo_name" || -n "${seen_repo[$repo_name]:-}" ]]; then
            continue
        fi
        seen_repo[$repo_name]=1
        merged_repos+=("$repo_name")
    done

    if [[ ${#merged_repos[@]} -eq 0 ]]; then
        log_info "No specific repositories to clone for this role."
        return
    fi

    local gh_available=false
    if command -v gh &> /dev/null; then
        gh_available=true
    else
        log_warn "GitHub CLI 'gh' is not installed."
        if install_with_package_manager "gh" "gh"; then
            log_success "'gh' installed successfully."
            # Re-check after installation attempt
            if command -v gh &> /dev/null; then
                gh_available=true
            else
                log_warn "'gh' still missing after attempted installation. Using git+SSH fallback."
            fi
        else
            log_warn "Unable to install 'gh'. Falling back to direct git clone over SSH."
        fi
    fi

    log_info "Preparing to manage ${#merged_repos[@]} repositories in '$gft_workspace'."
    for repo_name in "${merged_repos[@]}"; do
        local target_dir="$gft_workspace/$repo_name"
        if [ -d "$target_dir" ]; then
            log_info "Repository '$repo_name' already exists at '$target_dir'. Skipping."
            continue
        fi

        local approx_size="unknown"
        if $gh_available; then
            local disk_usage
            disk_usage=$(gh repo view "GenCr-ft/$repo_name" --json diskUsage --jq '.diskUsage' 2>/dev/null | tr -d '\r' | tr -d ' ')
            if [[ -n "$disk_usage" && "$disk_usage" =~ ^[0-9]+$ ]]; then
                local size_mb=$(( (disk_usage + 1023) / 1024 ))
                approx_size="~${size_mb} MB"
            else
                approx_size="unknown (gh data unavailable)"
            fi
        else
            approx_size="unknown (gh CLI unavailable)"
        fi

        log_info "Role: $role_name | Repository: $repo_name | Approx Size: $approx_size | Target: $target_dir"
        if confirm_action "Clone '$repo_name'?"; then
            if $gh_available; then
                run_command_with_logging gh repo clone "GenCr-ft/$repo_name" "$target_dir"
            else
                run_command_with_logging git clone "git@github.com:GenCr-ft/${repo_name}.git" "$target_dir"
            fi
        else
            log_warn "User opted to skip cloning '$repo_name'."
        fi
    done

    log_success "Repository cloning phase completed."
}


# Writes GFT_PLT_ROOT and GFT_WORKSPACE into the shell profile so gft can
# locate gcs-plt-tools without relying on the file-tree heuristic.
configure_gft_cli() {
    if ! install_gft_cli "false"; then
        log_error "Unable to install or repair gft before environment configuration."
        return 1
    fi

    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v gft &>/dev/null; then
        log_error "gft command not found after delegated installation."
        return 1
    fi

    log_info "Configuring gft CLI environment variables..."

    local plt_root="${GFT_PROJECTS_HOME:-$HOME/gft_studio}/gcs-plt-tools"
    local workspace="${GFT_PROJECTS_HOME:-$HOME/gft_studio}"

    local shell_profile_file=""
    if [ -n "${BASH_VERSION:-}" ]; then
        shell_profile_file="$HOME/.bashrc"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        shell_profile_file="$HOME/.zshrc"
    fi

    if [ -n "$shell_profile_file" ]; then
        local start_marker="# GENCRAFT ENVIRONMENT - START"
        local end_marker="# GENCRAFT ENVIRONMENT - END"
        touch "$shell_profile_file"
        if ! grep -qF "$start_marker" "$shell_profile_file"; then
            echo -e "\n$start_marker\n# Managed by gft-onboarding.sh — do not edit manually.\n$end_marker" >> "$shell_profile_file"
        fi
        for var_assignment in "GFT_PLT_ROOT=${plt_root}" "GFT_WORKSPACE=${workspace}"; do
            local var_name="${var_assignment%%=*}"
            if grep -qF "export ${var_assignment}" "$shell_profile_file"; then
                log_info "${var_name} is already set to the correct value."
            elif grep -qF "export ${var_name}=" "$shell_profile_file"; then
                _sed_inplace "s|^export ${var_name}=.*$|export ${var_assignment}|" "$shell_profile_file"
                log_info "Updated ${var_name} in $shell_profile_file"
            else
                _sed_inplace "s|^${end_marker}$|export ${var_assignment}\n${end_marker}|" "$shell_profile_file"
                log_info "Added export ${var_assignment} to $shell_profile_file"
            fi
        done
    fi

    # Export for the remainder of this session.
    export GFT_PLT_ROOT="$plt_root"
    export GFT_WORKSPACE="$workspace"

    log_success "gft CLI configured. GFT_PLT_ROOT=$plt_root"
}

final_validation() {
    log_info "Executing final validation checks..."

    local gft_status=0
    if command -v gft &>/dev/null; then
        if gft version &>/dev/null; then
            log_success "gft-cli is installed: $(gft version)"
        else
            gft_status=$?
            log_error "gft version failed (exit $gft_status)."
        fi
    else
        log_warn "gft-cli is not available; skipping its validation."
        gft_status=1
    fi

    local standards_dir
    local projects_root="${GFT_PROJECTS_HOME:-$HOME/gft_studio}"
    standards_dir="${projects_root}/gcs-core-governance"
    local precommit_status=0

    if ! command -v pre-commit &> /dev/null; then
        log_warn "pre-commit command not found; cannot run repository validation."
        precommit_status=1
    elif [ ! -d "$standards_dir" ]; then
        log_warn "Expected repository '$standards_dir' is missing; skipping pre-commit validation."
        precommit_status=1
    else
        if (cd "$standards_dir" && pre-commit run --all-files); then
            log_success "pre-commit hooks passed for gcs-core-governance."
        else
            precommit_status=$?
            log_error "pre-commit run reported issues (exit $precommit_status)."
        fi
    fi

    if [[ $gft_status -eq 0 && $precommit_status -eq 0 ]]; then
        log_success "Final validation complete. All automated checks succeeded."
    else
        log_warn "Final validation finished with warnings. Review the logs above for remediation steps."
    fi
}

# Configures environment variables based on the user's role.
# $1: role_name (mandatory)
# $2: shell_profile_for_test (optional, used only for testing)
configure_environment_variables() {
    local role_name="$1"
    local shell_profile_for_test="${2:-}" # Optional: override profile path for testing
    log_info "Configuring environment variables for role: $role_name"

    # 1. Detect the shell profile file
    local shell_profile_file=""
    if [ -n "$shell_profile_for_test" ]; then
        shell_profile_file="$shell_profile_for_test"
        log_info "Using provided test profile file: $shell_profile_file"
    elif [ -n "${BASH_VERSION:-}" ]; then
        shell_profile_file="$HOME/.bashrc"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        shell_profile_file="$HOME/.zshrc"
    else
        log_warn "Could not detect Bash or Zsh. Skipping shell profile configuration."
        return
    fi

    if [ -z "$shell_profile_for_test" ]; then
      log_info "Detected shell profile: $shell_profile_file"
    fi
    # Ensure the file exists for both tests and normal execution
    touch "$shell_profile_file"

    if [ -z "${GFT_SSOT_PATH:-}" ]; then
        log_warn "GFT_SSOT_PATH is not defined; skipping environment variable configuration."
        return
    fi

    # 2. Get list of variables via the Markdown parser
    local python_helper_script="${SCRIPT_DIR}/includes/get_standard_env_vars.py"
    if [ ! -f "$python_helper_script" ]; then
        log_error "FATAL: Environment variable helper not found at $python_helper_script"
        return 1
    fi

    if [ ! -f "${GFT_SSOT_PATH}/tooling/ENV_VARIABLES_STANDARD.md" ]; then
        log_error "Missing ENV_VARIABLES_STANDARD.md in ${GFT_SSOT_PATH}/tooling"
        return 1
    fi

    mapfile -t required_vars < <(python3 "$python_helper_script" "$role_name")

    if [[ ${#required_vars[@]} -eq 0 ]]; then
        log_info "No specific environment variables to configure for this role."
        return
    fi

    # 3. Ensure the Gencraft configuration block exists
    local start_marker="# GENCRAFT ENVIRONMENT - START"
    local end_marker="# GENCRAFT ENVIRONMENT - END"
    if ! grep -qF "$start_marker" "$shell_profile_file"; then
        log_info "Adding Gencraft configuration block to $shell_profile_file..."
        echo -e "\n$start_marker\n# This block is managed by the Gencraft onboarding script. Do not edit manually.\n$end_marker" >> "$shell_profile_file"
    fi

    # 4. Add each variable if it does not already exist
    for var_line in "${required_vars[@]}"; do
        local var_name="${var_line%%=*}"
        local var_value="${var_line#*=}"

        if grep -qF "export $var_name=" "$shell_profile_file"; then
            log_info "Variable '$var_name' is already configured."
        else
            log_info "Adding variable '$var_name' to shell profile."
            # Insert the new export line immediately before the end marker.
            # This avoids the corruption caused by grep -vF which would strip every
            # occurrence of the end marker in the file, moving post-block content
            # into the managed block.
            _sed_inplace "s|^${end_marker}$|export ${var_name}=${var_value}\n${end_marker}|" "$shell_profile_file"

            if [[ "$var_name" == "GFT_PROJECTS_HOME" ]]; then
                local evaluated_path
                # Safe expansion: strip quotes, then replace ~ or literal $HOME with $HOME.
                # eval is intentionally avoided here to prevent shell injection.
                local stripped="${var_value//\"/}"
                if [[ "$stripped" == '~'* ]]; then
                    evaluated_path="${HOME}${stripped:1}"
                elif [[ "$stripped" == '$HOME'* ]]; then
                    evaluated_path="${HOME}${stripped:5}"
                else
                    evaluated_path="$stripped"
                fi
                log_info "Creating workspace directory at $evaluated_path..."
                mkdir -p "$evaluated_path"
            fi
        fi
    done

    log_success "Environment variables configured. Please restart your terminal."
}
