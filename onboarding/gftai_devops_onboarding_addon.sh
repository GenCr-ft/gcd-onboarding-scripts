#!/usr/bin/env bash

# G@FT.ai Studio - DevOps Onboarding Addon Script
# Version: 1.2.2 (Correct yq/tofu download path before sudo mv)
# Maintainer: Gem BB (Camille - Automation)
# Target OS: Linux, macOS, WSL2 (Bash environment)

# --- Configuration & Globals (Defaults) ---
readonly COLOR_BLUE="\033[1;34m"; readonly COLOR_GREEN="\033[1;32m"; readonly COLOR_RED="\033[1;31m";
readonly COLOR_YELLOW="\033[1;33m"; readonly COLOR_RESET="\033[0m";

TOFU_VERSION_TARGET=""
AWS_CLI_VERSION_TARGET=""
JQ_VERSION_TARGET=""
YQ_VERSION_TARGET="latest"

GFTAI_MAIN_WORKSPACE_PARENT_DIR_DEFAULT="${HOME}/gftai_studio_workspace"
DEVOPS_TOOLS_PARENT_DIR_DEFAULT="${GFTAI_MAIN_WORKSPACE_PARENT_DIR_DEFAULT}/devops_tools"
DEVOPS_PYTHON_VENV_NAME_DEFAULT=".venv-devops-tools"

AWS_DEFAULT_PROFILE_DEFAULT="default"
AWS_DEFAULT_REGION_DEFAULT="eu-west-3"
DEVOPS_VSCODE_EXTRA_EXTENSIONS_DEFAULT="hashicorp.terraform,amazonwebservices.aws-toolkit-vscode,timonwong.shellcheck"

TOFU_VERSION=""; AWS_CLI_VERSION=""; JQ_VERSION=""; YQ_VERSION="";
DEVOPS_TOOLS_PARENT_DIR=""; DEVOPS_PYTHON_VENV_PATH="";
AWS_DEFAULT_PROFILE=""; AWS_DEFAULT_REGION="";
DEVOPS_VSCODE_EXTENSIONS_TO_INSTALL=()

# --- Helper Functions ---
info() { echo -e "${COLOR_BLUE}[INFO-DevOps]${COLOR_RESET} $1"; }
success() { echo -e "${COLOR_GREEN}[SUCCESS-DevOps]${COLOR_RESET} $1"; }
warning() { echo -e "${COLOR_YELLOW}[WARNING-DevOps]${COLOR_RESET} $1"; }
error() { echo -e "${COLOR_RED}[ERROR-DevOps]${COLOR_RESET} $1"; if [[ "$2" == "exit" ]]; then exit 1; fi; }
ask_yes_no() {
    local question="$1"; local default_answer="${2:-yes}";
    while true; do
        if [[ "$default_answer" == "yes" ]]; then read -r -p "$(echo -e "${COLOR_YELLOW}[QUESTION-DevOps]${COLOR_RESET}") ${question} [Y/n]: " answer; answer=${answer:-Y};
        else read -r -p "$(echo -e "${COLOR_YELLOW}[QUESTION-DevOps]${COLOR_RESET}") ${question} [y/N]: " answer; answer=${answer:-N}; fi
        case "$answer" in [Yy]* ) return 0;; [Nn]* ) return 1;; * ) echo "Please answer yes (y) or no (n).";; esac
    done
}
command_exists() { command -v "$1" >/dev/null 2>&1; }
OS_TYPE=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then OS_TYPE="linux";
elif [[ "$OSTYPE" == "darwin"* ]]; then OS_TYPE="macos";
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then OS_TYPE="windows_bash";
else OS_TYPE="unknown"; fi

try_install_sys_package() {
    local pkg_name_human="$1"; local pkg_name_apt="$2"; local pkg_name_brew="$3"
    if ! ask_yes_no "Attempt automatic installation of ${pkg_name_human}?"; then info "Skipping install of ${pkg_name_human}."; return 1; fi
    if [[ "${OS_TYPE}" == "linux" ]] && command_exists apt-get; then
        info "Installing ${pkg_name_apt} via apt (sudo)..."
        if sudo apt-get update && sudo apt-get install -y "${pkg_name_apt}"; then success "${pkg_name_human} installed (apt)."; return 0;
        else error "${pkg_name_human} install failed (apt)."; fi
    elif ([[ "${OS_TYPE}" == "macos" ]] || [[ "${OS_TYPE}" == "linux" ]]) && command_exists brew; then
        info "Installing ${pkg_name_brew} via brew..."
        if brew install "${pkg_name_brew}"; then success "${pkg_name_human} installed (brew)."; return 0;
        else error "${pkg_name_human} install failed (brew)."; fi
    else warning "No common package manager for ${pkg_name_human}."; fi
    info "Please install ${pkg_name_human} manually."; return 1
}
# End Helper Functions

# --- Configuration Loading for DevOps Script ---
load_devops_env_file() {
    info "Loading configurations from .env.devops file..."
    local env_file="./.env.devops"; if [ ! -f "$env_file" ]; then env_file="${HOME}/.config/gftai_onboarding/.env.devops"; fi
    if [ -f "$env_file" ]; then
        info "Found .env.devops at '$env_file'. Loading..."
        while IFS='=' read -r key value || [ -n "$key" ]; do
            value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            key=$(echo "$key" | tr -d '[:space:]'); if [[ -z "$key" || "$key" == \#* ]]; then continue; fi
            case "$key" in
                TOFU_VERSION_TARGET) TOFU_VERSION_TARGET_DEFAULT="$value" ;; AWS_CLI_VERSION_TARGET) AWS_CLI_VERSION_TARGET_DEFAULT="$value" ;;
                JQ_VERSION_TARGET) JQ_VERSION_TARGET_DEFAULT="$value" ;; YQ_VERSION_TARGET) YQ_VERSION_TARGET_DEFAULT="$value" ;;
                DEVOPS_TOOLS_PARENT_DIR) DEVOPS_TOOLS_PARENT_DIR_DEFAULT="$value" ;; DEVOPS_PYTHON_VENV_NAME) DEVOPS_PYTHON_VENV_NAME_DEFAULT="$value" ;;
                AWS_DEFAULT_PROFILE) AWS_DEFAULT_PROFILE_DEFAULT="$value" ;; AWS_DEFAULT_REGION) AWS_DEFAULT_REGION_DEFAULT="$value" ;;
                DEVOPS_VSCODE_EXTRA_EXTENSIONS) DEVOPS_VSCODE_EXTRA_EXTENSIONS_DEFAULT="$value" ;; *) warning "Unknown key in .env.devops: $key" ;;
            esac
        done < <(tr -d '\r' < "$env_file"); success ".env.devops processed."
    else info ".env.devops not found. Using script defaults for DevOps tools."; fi
    TOFU_VERSION="${TOFU_VERSION_TARGET_DEFAULT:-latest}"; AWS_CLI_VERSION="${AWS_CLI_VERSION_TARGET_DEFAULT}"; JQ_VERSION="${JQ_VERSION_TARGET_DEFAULT}"; YQ_VERSION="${YQ_VERSION_TARGET_DEFAULT:-latest}";
    DEVOPS_TOOLS_PARENT_DIR="${DEVOPS_TOOLS_PARENT_DIR_DEFAULT/#\~/$HOME}"; DEVOPS_PYTHON_VENV_PATH="${DEVOPS_TOOLS_PARENT_DIR}/${DEVOPS_PYTHON_VENV_NAME_DEFAULT}";
    AWS_DEFAULT_PROFILE="${AWS_DEFAULT_PROFILE_DEFAULT:-default}"; AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION_DEFAULT:-eu-west-3}";
    IFS=',' read -r -a DEVOPS_VSCODE_EXTENSIONS_TO_INSTALL <<< "$DEVOPS_VSCODE_EXTRA_EXTENSIONS_DEFAULT"
}
confirm_devops_configurations() {
    info "DEVOPS SCRIPT - FINAL CONFIGURATION CHECK:"; echo "-----------------------------------------------------"
    info "  OpenTofu Version:          ${COLOR_GREEN}${TOFU_VERSION}${COLOR_RESET}"
    info "  AWS CLI Version (in venv): ${COLOR_GREEN}${AWS_CLI_VERSION:-latest}${COLOR_RESET}"
    info "  jq Version (pkg manager):  ${COLOR_GREEN}${JQ_VERSION:-latest}${COLOR_RESET}"
    info "  yq Version (GitHub):       ${COLOR_GREEN}${YQ_VERSION}${COLOR_RESET}"
    info "  DevOps Tools Parent Dir:   ${COLOR_GREEN}${DEVOPS_TOOLS_PARENT_DIR}${COLOR_RESET}"
    info "  DevOps Python Venv Path:   ${COLOR_GREEN}${DEVOPS_PYTHON_VENV_PATH}${COLOR_RESET}"
    info "  AWS Profile (for config):  ${COLOR_GREEN}${AWS_DEFAULT_PROFILE}${COLOR_RESET}"
    info "  AWS Region (for config):   ${COLOR_GREEN}${AWS_DEFAULT_REGION}${COLOR_RESET}"
    info "  Extra VS Code Extensions:  ${COLOR_GREEN}${DEVOPS_VSCODE_EXTENSIONS_TO_INSTALL[*]}${COLOR_RESET}"
    echo "-----------------------------------------------------"
    if ! ask_yes_no "Proceed with these DevOps configurations?"; then error "DevOps config not confirmed. Exiting." "exit"; fi
    success "DevOps configurations confirmed."
}

# --- Section D0: DevOps Script Prerequisites ---
check_devops_prerequisites() {
    info "SECTION D0: Checking Prerequisites for DevOps Addon Script..."
    local all_prereqs_met=true
    if ! command_exists python3 || ! python3 -m pip --version >/dev/null 2>&1; then error "Python 3/pip not available. Run main 'gftai_onboarding.sh' first."; all_prereqs_met=false; fi
    if ! command_exists unzip; then warning "'unzip' needed for OpenTofu."; if ! try_install_sys_package "unzip" "unzip" "unzip"; then all_prereqs_met=false; fi; fi
    if ! command_exists curl; then warning "'curl' needed for downloads."; if ! try_install_sys_package "curl" "curl" "curl"; then all_prereqs_met=false; fi; fi
    if [[ "${OS_TYPE}" == "linux" ]] && command_exists apt-get; then
        local venv_pkg_installed=false; local py_ver_short; py_ver_short=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
        local python_venv_pkg_specific=""; if [ -n "$py_ver_short" ]; then python_venv_pkg_specific="python${py_ver_short}-venv"; if dpkg -s "${python_venv_pkg_specific}" >/dev/null 2>&1 ; then success "Found: ${python_venv_pkg_specific}"; venv_pkg_installed=true; fi; fi
        if ! $venv_pkg_installed && ! dpkg -s python3-venv >/dev/null 2>&1 ; then
             warning "Package 'python3-venv' (or '${python_venv_pkg_specific}') missing."; local pkg_to_install="python3-venv"; if [ -n "$python_venv_pkg_specific" ]; then pkg_to_install="$python_venv_pkg_specific"; fi
             if ! try_install_sys_package "${pkg_to_install}" "${pkg_to_install}" ""; then warning "Failed to install ${pkg_to_install}."; else success "Installed ${pkg_to_install}."; fi
        elif ! $venv_pkg_installed && dpkg -s python3-venv >/dev/null 2>&1; then success "Package 'python3-venv' (generic) installed."; fi
    fi
    if ! $all_prereqs_met; then error "DevOps script prerequisites missing. Address and re-run." "exit"; fi
    success "DevOps script prerequisites met."; echo "-----------------------------------------------------"
}

# --- Section D2: Python Virtual Environment for DevOps ---
setup_devops_python_venv() {
    info "SECTION D2: Setting up Python Virtual Environment for DevOps Tools..."
    echo "-----------------------------------------------------"
    if ! command_exists python3; then error "Python 3 not found." "exit"; return 1; fi
    info "DevOps tools parent: ${DEVOPS_TOOLS_PARENT_DIR}"; info "Python venv path: ${DEVOPS_PYTHON_VENV_PATH}"
    local recreate_venv=false
    if [ -d "${DEVOPS_PYTHON_VENV_PATH}" ]; then
        success "Venv dir exists: ${DEVOPS_PYTHON_VENV_PATH}."
        if [ -x "${DEVOPS_PYTHON_VENV_PATH}/bin/pip" ] && "${DEVOPS_PYTHON_VENV_PATH}/bin/pip" --version >/dev/null 2>&1; then success "pip is OK in existing venv.";
        else warning "pip NOT found/working in existing venv: ${DEVOPS_PYTHON_VENV_PATH}."; if ask_yes_no "Existing venv seems broken. Remove and recreate?"; then
                info "Removing venv: ${DEVOPS_PYTHON_VENV_PATH}"; if rm -rf "${DEVOPS_PYTHON_VENV_PATH}"; then success "Removed venv."; recreate_venv=true; else error "Failed to remove venv."; return 1; fi
            else warning "Proceeding with potentially broken venv."; fi
        fi
    else recreate_venv=true; fi
    if [ "$recreate_venv" = true ]; then
        if [ ! -d "${DEVOPS_TOOLS_PARENT_DIR}" ]; then info "Creating parent dir: ${DEVOPS_TOOLS_PARENT_DIR}"; if ! mkdir -p "${DEVOPS_TOOLS_PARENT_DIR}"; then error "Failed: ${DEVOPS_TOOLS_PARENT_DIR}."; return 1; fi; success "Created: ${DEVOPS_TOOLS_PARENT_DIR}"; fi
        info "Creating Python venv (with --upgrade-deps): ${DEVOPS_PYTHON_VENV_PATH}"
        if python3 -m venv --upgrade-deps "${DEVOPS_PYTHON_VENV_PATH}"; then success "Python venv created.";
            info "Ensuring pip, setuptools, wheel are up-to-date in new venv...";
            if "${DEVOPS_PYTHON_VENV_PATH}/bin/python3" -m pip install --upgrade pip setuptools wheel; then success "pip/setuptools/wheel upgraded in venv.";
            else warning "Failed to upgrade pip/setuptools in venv."; fi
            if [ ! -f "${DEVOPS_PYTHON_VENV_PATH}/bin/pip" ]; then warning "pip still not found in new venv. Check python3-venv package."; fi
        else error "Failed to create Python venv. Ensure 'python3-venv' (or equivalent) is installed."; return 1; fi
    fi
    info "To activate DevOps venv: source \"${DEVOPS_PYTHON_VENV_PATH}/bin/activate\""; echo "-----------------------------------------------------"; return 0
}

# --- Section D1: DevOps Tooling Installation ---
install_opentofu() {
    info "Checking for OpenTofu CLI (tofu)..."
    if command_exists tofu; then current_tofu_version=$(tofu version | head -n1); success "OpenTofu already installed: ${current_tofu_version}"; return 0; fi
    warning "OpenTofu CLI not found."; if ! ask_yes_no "Install OpenTofu now?"; then info "Skipping OpenTofu."; return 1; fi
    local os_arch; case "$(uname -sm)" in "Linux x86_64") os_arch="linux_amd64" ;; "Linux aarch64") os_arch="linux_arm64" ;; "Darwin x86_64") os_arch="darwin_amd64" ;; "Darwin arm64") os_arch="darwin_arm64" ;; *) error "Unsupported OS/Arch for Tofu: $(uname -sm)."; return 1 ;; esac
    local tofu_dl_v; if [ -n "$TOFU_VERSION" ] && [ "$TOFU_VERSION" != "latest" ]; then tofu_dl_v="$TOFU_VERSION"; else info "Fetching latest OpenTofu version..."; tofu_dl_v=$(curl -fsSL https://api.github.com/repos/opentofu/opentofu/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/'); if [ -z "$tofu_dl_v" ]; then error "Could not fetch latest Tofu."; return 1; fi; info "Latest Tofu: ${tofu_dl_v}."; fi
    local dl_url="https://github.com/opentofu/opentofu/releases/download/v${tofu_dl_v}/tofu_${tofu_dl_v}_${os_arch}.zip";
    local temp_dl_dir; temp_dl_dir=$(mktemp -d tofu_dl_XXXXXX) # Create temp dir in current path or /tmp
    local install_p="/usr/local/bin";
    info "Downloading Tofu v${tofu_dl_v} for ${os_arch} to ${temp_dl_dir}/tofu.zip...";
    if curl -fsSL "${dl_url}" -o "${temp_dl_dir}/tofu.zip"; then info "Unzipping Tofu...";
        if unzip -q "${temp_dl_dir}/tofu.zip" -d "${temp_dl_dir}"; then info "Installing tofu to ${install_p} (sudo)...";
            if sudo mv "${temp_dl_dir}/tofu" "${install_p}/tofu" && sudo chmod +x "${install_p}/tofu"; then success "Tofu v${tofu_dl_v} installed."; if command_exists tofu; then tofu version; fi; rm -rf "${temp_dl_dir}"; return 0;
            else error "Failed to move tofu to ${install_p}."; fi
        else error "Failed to unzip Tofu."; fi
    else local curl_exit_code=$?; error "Failed to download Tofu (curl code: ${curl_exit_code}). URL: ${dl_url}"; fi
    rm -rf "${temp_dl_dir}"; info "Install Tofu manually: https://opentofu.org/docs/intro/install/"; return 1
}

install_aws_cli_in_venv() {
    info "Checking for AWS CLI (aws) within DevOps Python venv..."
    if [ ! -f "${DEVOPS_PYTHON_VENV_PATH}/bin/activate" ]; then error "DevOps Python venv not found/incomplete. Cannot install AWS CLI."; return 1; fi
    if [ ! -x "${DEVOPS_PYTHON_VENV_PATH}/bin/pip" ]; then error "pip not found/executable in venv. AWS CLI install will fail."; return 1; fi
    if "${DEVOPS_PYTHON_VENV_PATH}/bin/aws" --version >/dev/null 2>&1; then current_aws_version=$("${DEVOPS_PYTHON_VENV_PATH}/bin/aws" --version 2>&1); success "AWS CLI already in venv: ${current_aws_version}"; return 0; fi
    warning "AWS CLI not found in DevOps venv."; if ! ask_yes_no "Install AWS CLI v2 into '${DEVOPS_PYTHON_VENV_PATH}' now?"; then info "Skipping AWS CLI."; return 1; fi
    info "Installing AWS CLI v2 into Python venv via '${DEVOPS_PYTHON_VENV_PATH}/bin/pip'...";
    if "${DEVOPS_PYTHON_VENV_PATH}/bin/pip" install --upgrade awscli; then success "AWS CLI installed/updated in venv.";
        if "${DEVOPS_PYTHON_VENV_PATH}/bin/aws" --version >/dev/null 2>&1; then "${DEVOPS_PYTHON_VENV_PATH}/bin/aws" --version; else error "AWS CLI installed but command not found in venv path."; fi
        info "To use: source \"${DEVOPS_PYTHON_VENV_PATH}/bin/activate\""; return 0;
    else error "Failed to install AWS CLI into venv via pip."; info "Manual install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html (venv method)"; return 1; fi
}

install_jq() {
    info "Checking for jq..."; if command_exists jq; then success "jq installed: $(jq --version 2>&1)"; return 0; fi
    warning "jq not found."; if ! try_install_sys_package "jq" "jq" "jq"; then info "Install jq manually: https://stedolan.github.io/jq/download/"; return 1; fi
    if command_exists jq; then success "jq installed."; else error "jq still not found after install attempt."; return 1; fi
}

install_yq() {
    info "Checking for yq (Go version by Mike Farah)..."; if command_exists yq; then success "yq installed: $(yq --version 2>&1 | head -n1 || echo unknown)"; return 0; fi
    warning "yq not found."; if ! ask_yes_no "Install yq now?"; then info "Skipping yq."; return 1; fi
    local yq_dl_v; if [ -n "$YQ_VERSION" ] && [ "$YQ_VERSION" != "latest" ]; then yq_dl_v="$YQ_VERSION"; else info "Fetching latest yq version..."; yq_dl_v=$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'); if [ -z "$yq_dl_v" ]; then error "Could not fetch latest yq."; return 1; fi; info "Latest yq: ${yq_dl_v}."; fi
    local yq_os yq_arch; case "$(uname -s)" in Linux) yq_os="linux" ;; Darwin) yq_os="darwin" ;; *) error "Unsupported OS for yq: $(uname -s)."; return 1 ;; esac
    case "$(uname -m)" in x86_64) yq_arch="amd64" ;; arm64 | aarch64) yq_arch="arm64" ;; *) error "Unsupported Arch for yq: $(uname -m)."; return 1 ;; esac
    local yq_bin="yq_${yq_os}_${yq_arch}"; local yq_url="https://github.com/mikefarah/yq/releases/download/${yq_dl_v}/${yq_bin}";
    local temp_yq_dl_file; temp_yq_dl_file=$(mktemp -p "$HOME" yq_download_XXXXXX || mktemp -p "/tmp" yq_download_XXXXXX) # Try HOME first, then /tmp
    local install_p="/usr/local/bin";

    info "Downloading yq ${yq_dl_v} (${yq_bin}) to ${temp_yq_dl_file}..."
    if curl -fsSL "${yq_url}" -o "${temp_yq_dl_file}"; then
        info "Installing yq to ${install_p}/yq (requires sudo)...";
        if sudo mv "${temp_yq_dl_file}" "${install_p}/yq" && sudo chmod +x "${install_p}/yq"; then
            success "yq ${yq_dl_v} installed to ${install_p}/yq."
            if command_exists yq; then yq --version; fi; return 0;
        else
            error "Failed to move yq to ${install_p} or set permissions. Check sudo permissions."
            rm -f "${temp_yq_dl_file}" # Clean up temp file if mv failed
        fi
    else
        local curl_exit_code=$?
        error "Failed to download yq (curl code: ${curl_exit_code}). URL: ${yq_url}"
        rm -f "${temp_yq_dl_file}" # Clean up temp file
    fi
    info "Install yq (Mike Farah version) manually: https://github.com/mikefarah/yq/#install"; return 1
}

# --- Main DevOps Addon Script Logic ---
devops_main() {
    load_devops_env_file
    info "Starting G@FT.ai DevOps Onboarding Addon Script (v1.2.1)..."
    info "This script assumes the main onboarding script has been run."
    confirm_devops_configurations

    if ! check_devops_prerequisites; then exit 1; fi
    if ! setup_devops_python_venv; then
        warning "Python virtual environment setup for DevOps had issues. AWS CLI install might fail or install globally."
    fi

    info "SECTION D1: Installing DevOps Specific Tooling..."
    echo "-----------------------------------------------------"
    local all_tools_ok=true
    if ! install_opentofu; then all_tools_ok=false; fi
    if ! install_aws_cli_in_venv; then all_tools_ok=false; fi
    if ! install_jq; then all_tools_ok=false; fi
    if ! install_yq; then all_tools_ok=false; fi
    if $all_tools_ok; then success "DevOps CLI tools check/installation phase complete."; else warning "Some DevOps CLI tools had issues. Please review logs."; fi
    echo "-----------------------------------------------------"

    info "SECTION D3: AWS CLI Configuration..."
    echo "-----------------------------------------------------"
    info "AWS CLI should be installed (in venv: ${DEVOPS_PYTHON_VENV_PATH})."
    info "To configure (after activating venv: source \"${DEVOPS_PYTHON_VENV_PATH}/bin/activate\"):"
    info "  aws configure --profile ${AWS_DEFAULT_PROFILE}"
    info "Prompts: AWS Access Key ID, Secret Key, Default region (e.g., ${AWS_DEFAULT_REGION}), Output format (e.g., json)."
    info "Refer to G@FT.ai security guidelines for AWS credentials."
    echo "-----------------------------------------------------"

    info "SECTION D4: Installing VS Code Extensions for DevOps..."
    echo "-----------------------------------------------------"
    if command_exists code; then
        info "Installing/verifying DevOps VS Code extensions..."
        local ext_ok=true
        for ext_id in "${DEVOPS_VSCODE_EXTENSIONS_TO_INSTALL[@]}"; do
            if [ -n "$ext_id" ]; then info "Checking/Installing: $ext_id"
                if code --list-extensions | grep -qi "^${ext_id}$"; then success "'$ext_id' already installed.";
                else if code --install-extension "$ext_id" --force; then success "'$ext_id' installed."; else error "Failed to install '$ext_id'."; ext_ok=false; fi; fi
            fi
        done
        if $ext_ok; then success "DevOps VS Code extensions phase complete."; else warning "Some DevOps VS Code extensions had issues."; fi
        info "You may need to restart VS Code."
    else warning "VS Code CLI 'code' not found. Skipping DevOps VS Code extension installation."; fi
    echo "-----------------------------------------------------"

    success "####################################################################"
    success "# G@FT.ai DevOps Onboarding Addon Script has completed!            #"
    success "####################################################################"
    info "Review WARNINGS/ERRORS. Activate DevOps Python venv: source \"${DEVOPS_PYTHON_VENV_PATH}/bin/activate\""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    devops_main
fi
