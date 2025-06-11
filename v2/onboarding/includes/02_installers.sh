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

# Handles instructions for tools that require manual installation.
# $1: Package name (e.g., "Docker Desktop")
# $2: Recommended version
handle_manual_install() {
    local package_name="$1"
    local version="$2"
    log_warn "Tool '$package_name' requires manual installation."
    log_warn "Please install version '$version' or newer from its official website."
    if ! confirm_action "Have you installed '$package_name' manually and wish to continue?"; then
        log_error "Onboarding process aborted by user."
        exit 1
    fi
}

# --- Main Installation Dispatcher Functions ---

# Reads the spec for a given tool and calls the appropriate installer.
# $1: Logical tool name (e.g., "python")
install_tool() {
    local tool_name="$1"
    log_info "--------------------------------------------------"
    log_info "Processing tool: $tool_name"

    # Find the tool's specification in the tooling YAML data
    local tool_spec
    tool_spec=$(echo "$TOOLING_SPECS_YAML" | yq ".tools[] | select(.name == \"$tool_name\")")

    if [[ -z "$tool_spec" ]]; then
        log_warn "No specification found for tool '$tool_name' in SSoT. Skipping."
        return
    fi

    local method package version
    method=$(echo "$tool_spec" | yq -r '.method')
    package=$(echo "$tool_spec" | yq -r '.package')
    version=$(echo "$tool_spec" | yq -r '.version')

    case "$method" in
        package-manager)
            install_with_package_manager "$package"
            ;;
        nvm)
            log_info "Installing Node.js '$package' with nvm..."
            # shellcheck source=/dev/null
            . "$HOME/.nvm/nvm.sh"
            nvm install "$package"
            log_success "Node.js '$package' installed via nvm."
            ;;
        pyenv)
            log_info "Installing Python '$package' with pyenv..."
            if pyenv versions --bare | grep -q "^$package$"; then
                log_info "Python version $package is already installed by pyenv."
            else
                pyenv install "$package"
                log_success "Python '$package' installed via pyenv."
            fi
            ;;
        tfenv)
            log_info "Installing OpenTofu '$package' with tfenv..."
            if tfenv list | grep -q "$package"; then
                 log_info "OpenTofu version $package is already installed by tfenv."
            else
                tfenv install "$package"
                tfenv use "$package"
                log_success "OpenTofu '$package' installed via tfenv."
            fi
            ;;
        npm)
             log_info "Installing global npm package '$package'..."
             if npm list -g | grep -q "$package@"; then
                log_info "npm package '$package' is already installed globally."
             else
                npm install -g "$package"
                log_success "'$package' installed globally via npm."
             fi
             ;;
        manual)
            handle_manual_install "$package" "$version"
            ;;
        *)
            log_warn "Unknown installation method '$method' for tool '$tool_name'. Skipping."
            ;;
    esac
}

# Gets the list of required tools for a role and orchestrates their installation.
# $1: The selected role name
install_tools_for_role() {
    local role_name="$1"

    log_info "Fetching required tool list for role: $role_name"

    # Use yq to get the list of tool names for the selected role, including inherited ones
    local required_tools
    mapfile -t required_tools < <(echo "$ROLE_MATRIX_YAML" | yq -r "
        (.roles[] | select(.name == \"$role_name\") | .tools[].name?),
        (.roles[] | select(.name == \"$role_name\") | .inherits | select(. != null) | . as \$base_role | .roles[] | select(.name == \$base_role) | .tools[].name?)
    " | sort -u | sed '/^$/d') # sort -u to deduplicate, sed to remove empty lines

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
