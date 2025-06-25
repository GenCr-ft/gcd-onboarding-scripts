#!/usr/bin/env bash

# ==============================================================================
# Onboarding Script - Part 2: Tool Installation Functions
#
# Contains all logic for installing software based on the SSoT specs.
# This file is meant to be sourced by the main script.
# ==============================================================================

# --- Tool Installation Helper Functions ---

# Generic installer for system packages using apt or brew.
# $1: Package name to install.
install_with_package_manager() {
    local package_name="$1"
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
        if brew list "$package_name" &>/dev/null; then
            log_info "Package '$package_name' is already installed via Homebrew."
        else
            log_info "Installing '$package_name' with Homebrew..."
            brew install "$package_name"
            log_success "'$package_name' installed."
        fi
    elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
        if dpkg -s "$package_name" &>/dev/null; then
            log_info "Package '$package_name' is already installed via apt."
        else
            log_info "Installing '$package_name' with apt..."
            sudo apt-get update
            sudo apt-get install -y "$package_name"
            log_success "'$package_name' installed."
        fi
    fi
}

# --- Specific Tool Installers ---

install_tofu() {
    if command -v tofu &> /dev/null; then
        log_info "OpenTofu is already installed."
        return
    fi
    log_info "Installing OpenTofu (via tfenv)..."
    if ! command -v tfenv &> /dev/null; then
        log_info "tfenv not found, installing it..."
        git clone --depth=1 "https://github.com/tofuutils/tfenv.git" ~/.tfenv
        # This PATH change is for the current session only.
        # The main script should handle adding it to the shell profile permanently.
        export PATH="$HOME/.tfenv/bin:$PATH"
    fi
    log_info "Installing the latest version of OpenTofu..."
    tfenv install latest
    tfenv use latest
    log_success "OpenTofu installed."
}

install_shellcheck() {
    log_info "Installing shellcheck..."
    install_with_package_manager "shellcheck"
}

install_commitlint() {
    if ! command -v npm &> /dev/null; then
        log_error "npm (part of Node.js) is required to install commitlint. Please ensure Node.js is installed first."
        return 1
    fi
    log_info "Installing global npm packages for commitlint..."
    npm install -g @commitlint/cli @commitlint/config-conventional
    log_success "commitlint dependencies installed globally."
}

# --- Main Installation Dispatcher Function ---

# Reads the tool name and calls the appropriate installer function.
# $1: Logical tool name (e.g., "python", "opentofu")
install_tool() {
    local tool_name="$1"
    log_info "--------------------------------------------------"
    log_info "Processing tool requirement: $tool_name"

    case "$tool_name" in
        git|github-cli|docker|prettier|yq)
            install_with_package_manager "$tool_name"
            ;;
        node-lts)
            log_info "Installing Node.js LTS with nvm..."
            # Assuming nvm is installed as a prerequisite for this logic
            if [ -s "$HOME/.nvm/nvm.sh" ]; then
                # shellcheck source=/dev/null
                . "$HOME/.nvm/nvm.sh"
                nvm install --lts
                log_success "Node.js LTS installed."
            else
                log_error "nvm is not sourced correctly. Cannot install Node.js."
            fi
            ;;
        python)
            log_info "Ensuring Python is available..."
            # For now, we assume a system python is sufficient or pyenv is handled separately.
            if ! command -v python3 &>/dev/null; then
                log_warn "python3 command not found. Installation may be required."
                install_with_package_manager "python3"
            else
                log_info "python3 command found."
            fi
            ;;
        opentofu)
            install_tofu
            ;;
        shellcheck)
            install_shellcheck
            ;;
        commitlint)
            install_commitlint
            ;;
        *)
            log_warn "No specific installation logic defined for tool '$tool_name' in this script. Skipping."
            ;;
    esac
}

# Gets the list of required tools for a role and orchestrates their installation.
# $1: The selected role name
install_tools_for_role() {
    local role_name="$1"

    log_info "Fetching required tool list for role: $role_name"

    # Use yq to get the list of tool names for the selected role, including inherited ones
    mapfile -t required_tools < <(echo "$ROLE_MATRIX_YAML" | yq -r "
        (.roles[] | select(.name == \"common-base\") | .tools[]?),
        (.roles[] | select(.name == \"$role_name\") | .tools[]?),
        (.roles[] | select(.name == \"$role_name\") | .inherits | select(. != null) | . as \$base_role | .roles[] | select(.name == \$base_role) | .tools[]?)
    " | sort -u | sed '/^$/d' | sed '/null/d')

    if [[ ${#required_tools[@]} -eq 0 ]]; then
        log_info "No specific command-line tools to install for this role."
        return
    fi

    log_info "The following tools will be installed or verified: ${required_tools[*]}"
    if confirm_action "Proceed with tool installation?"; then
        for tool in "${required_tools[@]}"; do
            install_tool "$tool"
        done
        log_success "Tool installation phase complete."
    else
        log_warn "Tool installation skipped by user."
    fi
}
