#!/usr/bin/env bash

# G@FT.ai Studio - DevOps Onboarding Addon Script
# Version: 1.3.1 (PROJ-103 ADR-001 Repo Name Alignment, pre-commit handling)
# Maintainer: Camille (Gem AB - Automation Specialist)
# SSoT: gcd-onboarding-scripts/onboarding/gftai_devops_onboarding_addon.sh
# Based on previous version: 1.2.2

# --- Configuration & Globals (Defaults) ---
readonly COLOR_BLUE="\033[1;34m"; readonly COLOR_GREEN="\033[1;32m"; readonly COLOR_RED="\033[1;31m";
readonly COLOR_YELLOW="\033[1;33m"; readonly COLOR_RESET="\033[0m";

# Default versions for tools - these can be overridden by sourcing a .env file
# or by setting them before calling this script if it's sourced by another.
TOFU_VERSION_TARGET="${TOFU_VERSION_TARGET:-1.6.0}" # Example, align with IAC_001_OpenTofu_Tooling_Standard.md
AWS_CLI_VERSION_TARGET="${AWS_CLI_VERSION_TARGET:-2.15.0}" # Example
JQ_VERSION_TARGET="${JQ_VERSION_TARGET:-1.6}" # Example
YQ_VERSION_TARGET="${YQ_VERSION_TARGET:-v4.40.5}" # Example, yq versioning is often 'vX.Y.Z'
PRECOMMIT_VERSION_TARGET_MAJOR="${PRECOMMIT_VERSION_TARGET_MAJOR:-2}" # For pre-commit check

GFTAI_ORG_NAME_DEFAULT="GenCr-ft"
GFTAI_MAIN_WORKSPACE_PARENT_DIR_DEFAULT="${HOME}/gftai_studio_workspace"
DEVOPS_TOOLS_PARENT_DIR_DEFAULT="${GFTAI_MAIN_WORKSPACE_PARENT_DIR_DEFAULT}/devops_tools"
DEVOPS_PYTHON_VENV_NAME_DEFAULT=".venv-devops-tools"

AWS_DEFAULT_PROFILE_DEFAULT="default"
AWS_DEFAULT_REGION_DEFAULT="eu-west-3"

# Use new repo names based on Lug's list and clarifications
REPO_IAC_NAME_DEFAULT="gencraft-iac" # As per Lug: "je n'ai pas encore migré gencraft-iac"
REPO_DEVOPS_AUTOMATION_NAME_DEFAULT="gcd-onboarding-scripts" # New name for this script's home

# VSCode extensions specific to DevOps, supplementing the main onboarding script's list
DEVOPS_VSCODE_EXTENSIONS_TO_INSTALL=(
    "hashicorp.terraform" # Already in main list, but good to ensure for DevOps
    "amazonwebservices.aws-toolkit-vscode"
    # Other extensions from the main list like YAML, Shellcheck, Docker, Python are also highly relevant
    # No need to repeat them if main onboarding script installs them. This list can be for *additional* ones.
    # For now, assuming main list is comprehensive and these are just to emphasize or add minor ones.
)

# --- Global Variables (initialized in devops_main) ---
SCRIPT_DIR_DEVOPS_ADDON=""
OS_TYPE_DEVOPS_ADDON="" # To avoid conflict if sourced
# Variables for tool versions (will be populated from defaults or .env)
TOFU_VERSION=""; AWS_CLI_VERSION=""; JQ_VERSION=""; YQ_VERSION="";
DEVOPS_TOOLS_PARENT_DIR=""; DEVOPS_PYTHON_VENV_PATH="";
AWS_DEFAULT_PROFILE=""; AWS_DEFAULT_REGION="";
GFTAI_ORG_NAME="" # Will be inherited or use default

# --- Utility Functions (Adopted from gftai_onboarding.sh v1.3.5 for consistency) ---
FAIL_COUNT_DEVOPS_ADDON=0
WARN_COUNT_DEVOPS_ADDON=0

_devops_addon_print_status() {
    local message="$1"; local status="$2"; local prefix;
    case "$status" in
        OK)       prefix="[${COLOR_GREEN}OK${COLOR_RESET}]     ";;
        ERROR)    prefix="[${COLOR_RED}ERROR${COLOR_RESET}]  "; ((FAIL_COUNT_DEVOPS_ADDON++));;
        WARN)     prefix="[${COLOR_YELLOW}WARN${COLOR_RESET}]   "; ((WARN_COUNT_DEVOPS_ADDON++));;
        INFO)     prefix="[${COLOR_CYAN}INFO${COLOR_RESET}]   ";;
        STEP)     prefix="[${COLOR_BLUE}STEP${COLOR_RESET}]   ";;
        ACTION)   prefix="${COLOR_YELLOW}ACTION${COLOR_RESET}: ";;
        SUCCESS)  prefix="[${COLOR_GREEN}SUCCESS${COLOR_RESET}]";;
        *)        prefix="[????]   ";;
    esac; echo -e "$prefix$message";
}

d_success() { _devops_addon_print_status "$1" "SUCCESS"; }
d_error() { _devops_addon_print_status "$1" "ERROR"; }
d_warning() { _devops_addon_print_status "$1" "WARN"; }
d_info() { _devops_addon_print_status "$1" "INFO"; }
d_step_info() { _devops_addon_print_status "$1" "STEP"; }

command_exists() { command -v "$1" &>/dev/null; }
ensure_dir() {
    if [ ! -d "$1" ]; then
        if mkdir -p "$1"; then
            d_info "Created directory: $1"
        else
            d_error "Failed to create directory: $1 ! Please check permissions or path."
        fi
    fi
}
d_confirm_action() { # Renamed to avoid conflict if sourced
    local question="$1"; local default_answer="${2:-yes}"; local prompt_options="[Y/n]";
    if [[ "$default_answer" =~ ^(no|n|N)$ ]]; then prompt_options="[y/N]"; fi
    while true; do _devops_addon_print_status "$question $prompt_options " "ACTION"; read -r answer; answer="${answer:-$default_answer}";
        case "$answer" in [Yy]|[Yy][Ee][Ss]) return 0;; [Nn]|[Nn][Oo]) return 1;; *) d_error "Invalid response. Please answer 'yes' or 'no'.";; esac; done;
}

# --- Tool Installation/Verification Functions ---
# (These functions are adapted from the original gftai_devops_onboarding_addon.sh
#  and use the new logging functions. They might also benefit from some robustness improvements
#  similar to those applied to the main onboarding script if run completely standalone.)

check_and_install_tofu() {
    d_step_info "D1.1: Checking/Installing OpenTofu (tofu)..."
    # ... (Logic from original, ensure TOFU_VERSION_TARGET is used) ...
    # Example:
    if ! command_exists tofu || ! tofu version | grep -q "${TOFU_VERSION_TARGET}"; then # Simplified check
        d_warning "OpenTofu version mismatch or not found. Target: ${TOFU_VERSION_TARGET}."
        if d_confirm_action "Install/Update OpenTofu ${TOFU_VERSION_TARGET} now?"; then
             # Add actual download/install logic for TOFU_VERSION_TARGET
             # For example, fetching from GitHub releases:
             d_info "Attempting to install OpenTofu ${TOFU_VERSION_TARGET}..."
             local os_type; os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
             local arch_type; arch_type=$(uname -m)
             if [[ "$arch_type" == "x86_64" ]]; then arch_type="amd64"; elif [[ "$arch_type" == "aarch64" ]]; then arch_type="arm64"; fi
             local tofu_url="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION_TARGET}/tofu_${TOFU_VERSION_TARGET}_${os_type}_${arch_type}.zip"
             local download_path="/tmp/tofu.zip"
             local install_path="${DEVOPS_TOOLS_PARENT_DIR}/tofu/bin" # Install to a local tools dir
             ensure_dir "$install_path"
             d_info "Downloading from $tofu_url..."
             if curl -sL "$tofu_url" -o "$download_path"; then
                 unzip -o "$download_path" -d "${install_path}" tofu || (unzip -o "$download_path" -d "${install_path}" && mv "${install_path}/tofu_${TOFU_VERSION_TARGET}_${os_type}_${arch_type}/tofu" "${install_path}/tofu") # Handle nested dir
                 chmod +x "${install_path}/tofu"
                 d_success "OpenTofu v${TOFU_VERSION_TARGET} downloaded to ${install_path}."
                 d_info "Please ensure ${install_path} is in your PATH or use the full path."
                 # Verify
                 if "${install_path}/tofu" version | grep -q "${TOFU_VERSION_TARGET}"; then d_success "OpenTofu v${TOFU_VERSION_TARGET} installed."; else d_error "OpenTofu installation failed or version mismatch."; fi
             else
                 d_error "Failed to download OpenTofu. Please install manually."
             fi
             rm -f "$download_path"
        else
            d_warning "Skipping OpenTofu installation/update."
        fi
    else
        d_success "OpenTofu found: $(tofu version | head -n1)"
    fi
    echo "-----------------------------------------------------"
} # Based on

check_and_install_aws_cli() {
    d_step_info "D1.2: Checking/Installing AWS CLI v2..."
    # ... (Logic from original, ensure AWS_CLI_VERSION_TARGET is used if specified) ...
    # Example:
    if ! command_exists aws || ! aws --version 2>&1 | grep -q "aws-cli/${AWS_CLI_VERSION_TARGET:-2}"; then # Check for v2 generally or specific target
        d_warning "AWS CLI v2 (target: ${AWS_CLI_VERSION_TARGET:-2.x.x}) not found or version mismatch."
        if d_confirm_action "Install/Update AWS CLI v2 now?"; then
            d_info "Attempting to install AWS CLI v2..."
            local install_path="${DEVOPS_TOOLS_PARENT_DIR}/aws-cli"
            ensure_dir "$install_path"
            if curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
               unzip -q -o /tmp/awscliv2.zip -d /tmp && \
               sudo /tmp/aws/install --bin-dir "${install_path}/bin" --install-dir "${install_path}/aws-cli" --update && \
               rm /tmp/awscliv2.zip && rm -rf /tmp/aws; then
                d_success "AWS CLI v2 installed/updated to ${install_path}/bin/aws."
                d_info "Please ensure ${install_path}/bin is in your PATH or use the full path."
                if "${install_path}/bin/aws" --version | grep -q "aws-cli/2"; then d_success "AWS CLI v2 confirmed."; else d_error "AWS CLI v2 installation issue."; fi
            else
                d_error "Failed to install AWS CLI v2. Please install manually."
            fi
        else
            d_warning "Skipping AWS CLI v2 installation/update."
        fi
    else
        d_success "AWS CLI v2 found: $(aws --version 2>&1)"
    fi
    echo "-----------------------------------------------------"
} # Based on

# ... (Similar updates for check_and_install_yq, check_and_install_jq) ...

setup_devops_python_venv() { # MODIFIED to include pre-commit if not globally available
    d_step_info "D2: Setting up Python Virtual Environment for DevOps Tools..."
    # ... (Venv creation logic unchanged from gftai_devops_onboarding_addon.sh v1.2.2) ...
    DEVOPS_PYTHON_VENV_PATH="${DEVOPS_TOOLS_PARENT_DIR}/${DEVOPS_PYTHON_VENV_NAME_DEFAULT}"
    if [ ! -d "${DEVOPS_PYTHON_VENV_PATH}" ]; then
        d_info "Creating Python virtual environment at ${DEVOPS_PYTHON_VENV_PATH}..."
        if python3 -m venv "${DEVOPS_PYTHON_VENV_PATH}"; then
            d_success "Python virtual environment created."
        else
            d_error "Failed to create Python virtual environment at ${DEVOPS_PYTHON_VENV_PATH}."
            d_info "Ensure 'python3-venv' is installed (sudo apt install python3-venv)."
            return 1
        fi
    else
        d_success "Python virtual environment already exists at ${DEVOPS_PYTHON_VENV_PATH}."
    fi

    d_info "Activating DevOps Python venv and installing/upgrading packages..."
    # shellcheck source=/dev/null
    source "${DEVOPS_PYTHON_VENV_PATH}/bin/activate"

    local py_packages=("python-terraform" "ansible" "boto3" "pre-commit") # Added pre-commit
    local all_py_ok=true
    for pkg in "${py_packages[@]}"; do
        d_info "Installing/Updating ${pkg} in venv..."
        if pip3 install --upgrade "${pkg}"; then
            d_success "${pkg} installed/updated."
        else
            d_error "Failed to install/update ${pkg}."
            all_py_ok=false
        fi
    done

    deactivate # Deactivate after installations
    if $all_py_ok; then d_success "DevOps Python tools setup complete in venv."; else d_warning "Some Python tools for DevOps venv had issues."; fi
    d_info "To use these tools, activate the venv: source \"${DEVOPS_PYTHON_VENV_PATH}/bin/activate\""
    echo "-------------------------------------------------------------------"
} # Based on

clone_devops_repos() { # MODIFIED for new repo names and pre-commit hook install attempt
    d_step_info "D3: Cloning/Verifying Core DevOps Repositories..."
    echo "---------------------------------------------------------"
    local current_script_dir_addon; current_script_dir_addon=$( cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )
    if [ -f "${current_script_dir_addon}/.env" ]; then # Check for .env specific to this addon script's location
        # shellcheck source=.env
        source "${current_script_dir_addon}/.env"; info "Loaded .env file specific to DevOps addon."
    fi

    # Use GFTAI_ORG_NAME which should be set by main onboarding script or its .env
    local org_name="${GFTAI_ORG_NAME:-$GFTAI_ORG_NAME_DEFAULT}"
    local workspace_dir="${GFTAI_WORKSPACE_PARENT_DIR:-$GFTAI_MAIN_WORKSPACE_PARENT_DIR_DEFAULT}"

    local repo_iac_name="${REPO_IAC_NAME_OVERRIDE:-$REPO_IAC_NAME_DEFAULT}"
    local repo_devops_automation_name="${REPO_DEVOPS_AUTOMATION_NAME_OVERRIDE:-$REPO_DEVOPS_AUTOMATION_NAME_DEFAULT}"

    ensure_dir "${workspace_dir}" # Ensure the main workspace parent exists

    local repos_to_clone_devops=()
    if [[ -n "$repo_iac_name" ]]; then repos_to_clone_devops+=("${repo_iac_name}"); fi
    if [[ -n "$repo_devops_automation_name" ]]; then repos_to_clone_devops+=("${repo_devops_automation_name}"); fi

    if [ ${#repos_to_clone_devops[@]} -eq 0 ]; then
        d_info "No specific DevOps repositories defined for cloning in this script's config. Skipping."
        echo "---------------------------------------------------------"
        return
    fi

    d_info "Target base directory for DevOps repos: ${workspace_dir}"
    d_info "Organization: ${org_name}"

    local all_cloned_successfully=true
    for repo_name_only in "${repos_to_clone_devops[@]}"; do
        local target_dir="${workspace_dir}/${repo_name_only}"
        if [ -d "${target_dir}/.git" ]; then
            d_success "Repository '${repo_name_only}' already exists at '${target_dir}'. Skipping clone."
        else
            ensure_dir "$target_dir"
            d_info "Cloning '${org_name}/${repo_name_only}' into '${target_dir}'..."
            if gh repo clone "${org_name}/${repo_name_only}" "${target_dir}" -- --depth 1 --single-branch --no-tags; then
                d_success "Repository '${org_name}/${repo_name_only}' cloned successfully."
                # Install pre-commit hooks if config exists
                if command_exists pre-commit && [ -f "${target_dir}/.pre-commit-config.yaml" ]; then
                    d_info "Found .pre-commit-config.yaml in ${repo_name_only}. Installing pre-commit hooks..."
                    if (cd "${target_dir}" && pre-commit install && pre-commit install --hook-type commit-msg && pre-commit install --hook-type pre-push); then
                        d_success "Pre-commit hooks installed successfully for ${repo_name_only}."
                    else
                        d_warning "Failed to install some pre-commit hooks for ${repo_name_only}."
                    fi
                fi
            else
                d_error "Failed to clone repository '${org_name}/${repo_name_only}'. Ensure 'gh' is authenticated for org '${org_name}'."
                all_cloned_successfully=false
            fi
        fi
    done

    if $all_cloned_successfully; then
        d_success "Core DevOps repositories cloning/verification phase complete."
    else
        d_warning "Some DevOps repositories could not be cloned. Please check logs."
    fi
    echo "---------------------------------------------------------"
} # Based on

# --- Main DevOps Addon Function ---
devops_main() {
    SCRIPT_DIR_DEVOPS_ADDON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Load .env if present (for overrides of REPO_IAC_NAME_DEFAULT etc.)
    if [ -f "${SCRIPT_DIR_DEVOPS_ADDON}/.env" ]; then source "${SCRIPT_DIR_DEVOPS_ADDON}/.env"; fi

    # Populate globalish vars for this script from defaults or .env
    TOFU_VERSION="${TOFU_VERSION_OVERRIDE:-$TOFU_VERSION_TARGET}"
    AWS_CLI_VERSION="${AWS_CLI_VERSION_OVERRIDE:-$AWS_CLI_VERSION_TARGET}"
    # ... and so on for JQ_VERSION, YQ_VERSION, DEVOPS_TOOLS_PARENT_DIR etc.
    DEVOPS_TOOLS_PARENT_DIR="${DEVOPS_TOOLS_PARENT_DIR_OVERRIDE:-$DEVOPS_TOOLS_PARENT_DIR_DEFAULT}"
    ensure_dir "$DEVOPS_TOOLS_PARENT_DIR" # Ensure tools parent dir exists

    OS_TYPE_DEVOPS_ADDON=$(uname -s) # Simplified OS detection for this script

    d_step_info "G@FT.ai DevOps Onboarding Addon Script v1.3.1 Initializing..."
    d_info "This script installs additional tools for DevOps engineers."

    d_step_info "SECTION D1: Installing Core DevOps CLIs..."
    check_and_install_tofu
    check_and_install_aws_cli
    # ... (call check_and_install_yq, check_and_install_jq) ...

    d_step_info "SECTION D2: Setting up Python Virtual Environment for DevOps Tools..."
    setup_devops_python_venv

    d_step_info "SECTION D3: Cloning/Verifying Core DevOps Repositories..."
    # Ensure gh is authenticated before cloning
    # This assumes GFTAI_ORG_NAME is available (e.g. from sourced main .env or default)
    # A full ensure_gh_authenticated call could be added here if this script is truly standalone often
    if ! command_exists gh || ! gh auth status -h "${GFTAI_ORG_NAME:-$GFTAI_ORG_NAME_DEFAULT}" &>/dev/null; then
        d_warning "GitHub CLI 'gh' not authenticated for org '${GFTAI_ORG_NAME:-$GFTAI_ORG_NAME_DEFAULT}'. Cloning DevOps repos might fail if private."
    fi
    clone_devops_repos

    d_step_info "SECTION D4: Installing VS Code Extensions for DevOps..."
    # ... (Logic from gftai_devops_onboarding_addon.sh v1.2.2 for VSCode extensions) ...
    # This part might be redundant if main onboarding script installs a comprehensive list.
    # For now, keeping it as per original addon script.
    if command_exists code; then
        d_info "Installing/verifying ADDITIONAL DevOps VS Code extensions..."
        local ext_ok=true
        for ext_id in "${DEVOPS_VSCODE_EXTENSIONS_TO_INSTALL[@]}"; do
            if [ -n "$ext_id" ]; then d_info "Checking/Installing: $ext_id"
                if code --list-extensions | grep -qi "^${ext_id}$"; then d_success "'$ext_id' already installed.";
                else if code --install-extension "$ext_id" --force; then d_success "'$ext_id' installed."; else d_error "Failed to install '$ext_id'."; ext_ok=false; fi; fi
            fi
        done
        if $ext_ok; then d_success "Additional DevOps VS Code extensions phase complete."; else d_warning "Some additional DevOps VS Code extensions had issues."; fi
        d_info "You may need to restart VS Code."
    else d_warning "VS Code CLI 'code' not found. Skipping additional DevOps VS Code extension installation."; fi
    echo "----------------------------------------------------"


    d_success "####################################################################"
    d_success "# G@FT.ai DevOps Onboarding Addon Script has completed!            #"
    d_success "####################################################################"
    d_info "Review WARNINGS/ERRORS. To activate DevOps Python venv: source \"${DEVOPS_PYTHON_VENV_PATH}/bin/activate\""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Set GFTAI_ORG_NAME from environment if main script not sourced, or use default
    GFTAI_ORG_NAME="${GFTAI_ORG_NAME:-$GFTAI_ORG_NAME_DEFAULT}"
    GFTAI_MAIN_WORKSPACE_PARENT_DIR="${GFTAI_MAIN_WORKSPACE_PARENT_DIR:-$GFTAI_MAIN_WORKSPACE_PARENT_DIR_DEFAULT}"
    # Initialize other potentially inherited vars if this script can be run truly standalone
    # For simplicity, assuming it's usually an add-on to the main script's environment.

    devops_main
fi
