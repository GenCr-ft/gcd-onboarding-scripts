#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_INSTALLERS_02
# Title: Onboarding Script - SSoT-Driven Tool Installers
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-09
# Last Modified Date: 2025-06-26
# Version: 2.3.0
#
# Description:
#   This script manages the installation of all required development tools. It
#   is driven by the SSoT (.tool-versions-gft) and the role matrix to ensure
#   a standardized environment. It includes specific installers for version
#   managers (nvm, pyenv), binaries from GitHub, and other packages.
#
# Usage:
#   This file is sourced by gft-onboarding.sh.
#
# Dependencies:
#   Functions from 01_helpers.sh.
#   External commands: curl, unzip, tar, sha256sum, sudo, nvm, pyenv.

# --- Helper for OS/Architecture Detection ---
detect_os_arch() {
    if [[ -n "${GFT_OS:-}" ]]; then return; fi
    GFT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch; arch=$(uname -m)
    case "$arch" in
        x86_64) GFT_ARCH="amd64" ;; aarch64|arm64) GFT_ARCH="arm64" ;; *) GFT_ARCH="$arch" ;;
    esac
    export GFT_OS GFT_ARCH
}

# --- Specific SSoT-driven Tool Installers ---

install_node() {
    local version="$1"; local nvm_version_string; nvm_version_string=$(echo "$version" | sed 's/-/\\//')
    log_info "Installing Node.js version '$nvm_version_string' via nvm..."
    if [ ! -s "$HOME/.nvm/nvm.sh" ]; then log_error "nvm not found." && return 1; fi
    . "$HOME/.nvm/nvm.sh" && nvm install "$nvm_version_string" && nvm alias default "$nvm_version_string"
    log_success "Node.js $version installed and set as default."
}

install_python() {
    local version="$1"
    log_info "Installing Python version '$version' via pyenv..."
    if ! command -v pyenv &>/dev/null; then log_error "pyenv not found." && return 1; fi
    pyenv install -s "$version" && pyenv global "$version"
    log_success "Python $version installed and set as global default."
}

install_binary_from_github() {
    local tool_name="$1"; local version="$2"; local repo_url="$3"; local bin_name_in_zip="$4"
    log_info "Installing $tool_name version '$version' from GitHub releases..."
    if command -v "$bin_name_in_zip" &>/dev/null && [[ "$(eval "$bin_name_in_zip --version")" == *"$version"* ]]; then log_info "$tool_name $version is already installed." && return 0; fi
    local install_dir="$HOME/.local/bin"; mkdir -p "$install_dir"; local file_prefix="${tool_name}_${version}"
    if [[ "$tool_name" == "gft-cli" ]]; then file_prefix="gft-cli-v${version}"; fi
    local release_file="${file_prefix}_${GFT_OS}_${GFT_ARCH}.tar.gz"
    local checksum_file="checksums.txt"
    local download_url="https://github.com/${repo_url}/releases/download/v${version}"
    if [[ "$tool_name" == "gft-cli" ]]; then download_url="https://github.com/${repo_url}/releases/download/gft-cli-v${version}"; fi
    cd /tmp || return 1
    log_info "Downloading $tool_name binary and checksums..." && curl -sSL -O "${download_url}/${release_file}" && curl -sSL -O "${download_url}/${checksum_file}"
    log_info "Verifying checksum..."
    if ! grep "$release_file" "$checksum_file" | sha256sum --check --status; then
        log_error "Checksum verification failed for $tool_name." && rm -f "$release_file" "$checksum_file" && return 1
    fi
    log_info "Installing $tool_name..." && tar -xzf "$release_file" && mv "$bin_name_in_zip" "${install_dir}/" && chmod +x "${install_dir}/${bin_name_in_zip}"
    rm -f "$release_file" "$checksum_file" && log_success "$tool_name $version installed to ${install_dir}/${bin_name_in_zip}"
}

install_aws_cli() {
    log_info "Installing AWS CLI v2..."
    if command -v aws &>/dev/null && [[ "$(aws --version 2>&1)" == *"aws-cli/2"* ]]; then log_info "AWS CLI v2 is already installed." && return 0; fi
    cd /tmp || return 1
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip -oq awscliv2.zip && sudo ./aws/install
    rm -rf aws awscliv2.zip && log_success "AWS CLI v2 installed."
}

install_hook_managers() {
    log_info "Installing global hook managers (pre-commit, lint-staged)..."
    if command -v npm &>/dev/null; then npm install -g lint-staged; else log_warn "npm not found, skipping lint-staged."; fi
    if command -v pip3 &>/dev/null; then pip3 install --user pre-commit; else log_warn "pip3 not found, skipping pre-commit."; fi
    log_success "Global hook managers installation attempted."
}

verify_docker() {
    log_info "Verifying Docker installation..."
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log_success "Docker is installed and the daemon is running."
    else
        log_error "Docker is not installed or the Docker daemon is not running. Please install Docker Desktop and start it."
    fi
}

install_commitlint() {
    log_info "Installing global npm packages for commitlint..."
    if ! command -v npm &>/dev/null; then log_error "npm is required to install commitlint." && return 1; fi
    npm install -g @commitlint/cli @commitlint/config-conventional
    log_success "commitlint dependencies installed."
}


# --- Main Installation Dispatcher ---
install_tool() {
    local tool_from_matrix="$1"
    log_info "--- Processing tool: $tool_from_matrix ---"
    local version; detect_os_arch
    case "$tool_from_matrix" in
        git) log_info "'git' is a core prerequisite handled at startup." ;;
        github-cli) install_with_package_manager "gh" ;;
        yq) install_with_package_manager "yq" ;;
        shellcheck) install_with_package_manager "shellcheck" ;;
        docker) verify_docker ;;
        commitlint) install_commitlint ;;
        node-lts) version=$(get_ssot_tool_version "nodejs"); [ -n "$version" ] && install_node "$version" || log_warn "No version for 'nodejs' in SSoT.";;
        python) version=$(get_ssot_tool_version "python"); [ -n "$version" ] && install_python "$version" || log_warn "No version for 'python' in SSoT.";;
        opentofu) version=$(get_ssot_tool_version "opentofu"); [ -n "$version" ] && install_binary_from_github "opentofu" "$version" "opentofu/opentofu" "tofu" || log_warn "No version for 'opentofu' in SSoT.";;
        gft-cli) version=$(get_ssot_tool_version "gft-cli"); [ -n "$version" ] && install_binary_from_github "gft-cli" "$version" "GenCr-ft/gft-cli" "gft" || log_warn "No version for 'gft-cli' in SSoT.";;
        aws-cli) install_aws_cli ;;
        git-hooks-managers) install_hook_managers ;;
        *) log_warn "No SSoT-driven installation logic defined for tool '$tool_from_matrix'." ;;
    esac
}

# --- Main Entry Point for Tool Installation ---
install_tools_for_role() {
    local role_name="$1"
    log_info "Fetching required tool list for role: '$role_name'..."
    local python_helper_script="${SCRIPT_DIR}/includes/get_role_tools.py"
    if [ ! -f "$python_helper_script" ]; then log_error "FATAL: Python helper script not found" && return 1; fi
    mapfile -t required_tools < <(echo "$ROLE_MATRIX_YAML" | python3 "$python_helper_script" "$role_name")
    if [[ ${#required_tools[@]} -eq 0 ]]; then log_info "No specific tools to install for this role." && return; fi
    log_info "The following tools will be installed or verified: ${required_tools[*]}"
    if [[ -z "${TEST_ENV:-}" ]]; then if ! confirm_action "Proceed with tool installation?"; then log_warn "Skipped by user." && return; fi; fi
    for tool in "${required_tools[@]}"; do install_tool "$tool"; done
    log_success "Tool installation phase complete."
}
