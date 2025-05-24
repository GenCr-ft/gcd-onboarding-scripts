#!/usr/bin/env bash

# G@FT.ai Studio - Developer Onboarding Script
# Version: 1.1.2 (Initial config display fix)
# Maintainer: Gem BB (Camille - Automation)
# Target OS: Linux, macOS, WSL2 (Bash environment)
#
# Purpose:
# This script checks for essential software prerequisites,
# guides for installations, and optionally attempts auto-installation.
# It configures Git (user.name, user.email locally per repo),
# SSH keys for GitHub, clones studio repositories,
# creates a VS Code workspace file, and installs recommended extensions.
# It can be configured via a .env file in the same directory.
#
# Idempotency: This script attempts to be idempotent.

# --- Configuration & Globals (Defaults) ---
# Colors for output
readonly COLOR_BLUE="\033[1;34m"
readonly COLOR_GREEN="\033[1;32m"
readonly COLOR_RED="\033[1;31m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_RESET="\033[0m"

# These can be overridden by a .env file
# --- .env Overridable Variables ---
GFTAI_ORG_NAME_DEFAULT="GenCr-ft"
GFTAI_WORKSPACE_PARENT_DIR_DEFAULT="${HOME}/gftai_studio_workspace"
GFTAI_PROJECTS_DIR_NAME_DEFAULT="${GFTAI_ORG_NAME_DEFAULT}"
GFTAI_VSCODE_WORKSPACE_FILENAME_DEFAULT="gftai-studio.code-workspace"
GIT_USER_NAME_ENV_DEFAULT=""
GIT_USER_EMAIL_ENV_DEFAULT=""
# --- End .env Overridable Variables ---

# These will be populated after loading .env and defaults
GFTAI_ORG_NAME=""
GFTAI_WORKSPACE_PARENT_DIR=""
GFTAI_PROJECTS_DIR=""
GFTAI_VSCODE_WORKSPACE_FILE=""

readonly GFTAI_REPOS=(
    "gencraft-client" "gencraft-server" "gencraft-pcg" "gencraft-service-auth"
    "gencraft-service-persistence" "gencraft-api-contracts" "gencraft-iac"
    "gencraft-devops-automation" "devops-standards" "gencraft-backlog"
    "gencraft-requirements" "gencraft-architecture" "gencraft-documentation"
    "gencraft-qa-tests" "gencraft-gem" ".github" "gencraft-studio-handbook"
)
readonly NODE_LTS_VERSION_MAJOR="20" # Target Node.js v20.x LTS
readonly VSCODE_COMMON_EXTENSIONS=(
    "eamodio.gitlens" "EditorConfig.EditorConfig" "yzhang.markdown-all-in-one"
    "DavidAnson.vscode-markdownlint" "dbaeumer.vscode-eslint" "esbenp.prettier-vscode"
    "ms-python.python"
)

GIT_USER_NAME=""
GIT_USER_EMAIL=""
# End Configuration & Globals

# --- Helper Functions ---
info() { echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"; }
success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"; }
warning() { echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"; }
error() { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"; if [[ "$2" == "exit" ]]; then exit 1; fi; }
ask_yes_no() {
    local question="$1"; local default_answer="${2:-yes}";
    while true; do
        if [[ "$default_answer" == "yes" ]]; then read -r -p "$(echo -e "${COLOR_YELLOW}[QUESTION]${COLOR_RESET}") ${question} [Y/n]: " answer; answer=${answer:-Y};
        else read -r -p "$(echo -e "${COLOR_YELLOW}[QUESTION]${COLOR_RESET}") ${question} [y/N]: " answer; answer=${answer:-N}; fi
        case "$answer" in [Yy]* ) return 0;; [Nn]* ) return 1;; * ) echo "Please answer yes (y) or no (n).";; esac
    done
}
command_exists() { command -v "$1" >/dev/null 2>&1; }
OS_TYPE=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then OS_TYPE="linux";
elif [[ "$OSTYPE" == "darwin"* ]]; then OS_TYPE="macos";
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then warning "Running in MinGW/Cygwin? Best run in WSL2, Linux, or macOS."; OS_TYPE="windows_bash";
else warning "Unsupported OS: $OSTYPE."; OS_TYPE="unknown"; fi
# End Helper Functions

# --- Configuration Loading & Validation ---
load_env_file() {
    info "Attempting to load configurations from .env file..."
    local env_file="./.env"; if [ ! -f "$env_file" ]; then env_file="${HOME}/.config/gftai_onboarding/.env"; fi # Check local then home
    if [ -f "$env_file" ]; then
        info "Found .env file at '$env_file'. Loading variables..."
        while IFS='=' read -r key value || [ -n "$key" ]; do
            value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            key=$(echo "$key" | tr -d '[:space:]')
            if [[ -z "$key" || "$key" == \#* ]]; then continue; fi
            case "$key" in
                GFTAI_ORG_NAME) GFTAI_ORG_NAME_DEFAULT="$value" ;;
                GFTAI_WORKSPACE_PARENT_DIR) GFTAI_WORKSPACE_PARENT_DIR_DEFAULT="$value" ;;
                GFTAI_PROJECTS_DIR_NAME) GFTAI_PROJECTS_DIR_NAME_DEFAULT="$value" ;;
                GFTAI_VSCODE_WORKSPACE_FILENAME) GFTAI_VSCODE_WORKSPACE_FILENAME_DEFAULT="$value" ;;
                GIT_USER_NAME_DEFAULT) GIT_USER_NAME_ENV_DEFAULT="$value" ;;
                GIT_USER_EMAIL_DEFAULT) GIT_USER_EMAIL_ENV_DEFAULT="$value" ;;
                *) warning "Unknown key in .env file: $key" ;;
            esac
        done < <(tr -d '\r' < "$env_file") # Process to remove \r for Windows-edited .env files
        success ".env file processed."
    else info ".env file not found. Using script defaults and interactive prompts."; fi

    GFTAI_ORG_NAME="${GFTAI_ORG_NAME_DEFAULT}"
    GFTAI_WORKSPACE_PARENT_DIR="${GFTAI_WORKSPACE_PARENT_DIR_DEFAULT/#\~/$HOME}"
    if [[ "${GFTAI_PROJECTS_DIR_NAME_DEFAULT}" == "\${GFTAI_ORG_NAME_DEFAULT}" || "${GFTAI_PROJECTS_DIR_NAME_DEFAULT}" == "${GFTAI_ORG_NAME}" ]] && [[ -z "$(grep '^GFTAI_PROJECTS_DIR_NAME=' "$env_file" 2>/dev/null)" || "$(grep '^GFTAI_PROJECTS_DIR_NAME=' "$env_file" 2>/dev/null | cut -d'=' -f2 | xargs)" == "\${GFTAI_ORG_NAME_DEFAULT}" ]]; then
      GFTAI_PROJECTS_DIR_NAME="${GFTAI_ORG_NAME}"
    else
      GFTAI_PROJECTS_DIR_NAME="${GFTAI_PROJECTS_DIR_NAME_DEFAULT}"
    fi
    GFTAI_PROJECTS_DIR="${GFTAI_WORKSPACE_PARENT_DIR}/${GFTAI_PROJECTS_DIR_NAME}"
    GFTAI_VSCODE_WORKSPACE_FILENAME="${GFTAI_VSCODE_WORKSPACE_FILENAME_DEFAULT}"
    GFTAI_VSCODE_WORKSPACE_FILE="${GFTAI_WORKSPACE_PARENT_DIR}/${GFTAI_VSCODE_WORKSPACE_FILENAME}"
}

confirm_configurations() {
    info "FINAL CONFIGURATION CHECK:"
    echo "-----------------------------------------------------"
    echo -e "  GitHub Organization Name:        ${COLOR_GREEN}${GFTAI_ORG_NAME}${COLOR_RESET}"
    echo -e "  Workspace Parent Directory:      ${COLOR_GREEN}${GFTAI_WORKSPACE_PARENT_DIR}${COLOR_RESET}"
    echo -e "  Projects Directory (for clones):   ${COLOR_GREEN}${GFTAI_PROJECTS_DIR}${COLOR_RESET}"
    echo -e "  VS Code Workspace File:          ${COLOR_GREEN}${GFTAI_VSCODE_WORKSPACE_FILE}${COLOR_RESET}"
    echo -e "  Git User Name (local per repo):  ${COLOR_GREEN}${GIT_USER_NAME}${COLOR_RESET}"
    echo -e "  Git User Email (local per repo): ${COLOR_GREEN}${GIT_USER_EMAIL}${COLOR_RESET}"
    echo "-----------------------------------------------------"
    if ! ask_yes_no "Are these configurations correct to proceed?"; then
        error "Configuration not confirmed. Please update your .env file or re-run to enter different values. Exiting." "exit"
    fi
    success "Configurations confirmed."
}
# End Configuration Loading & Validation

# --- Section 1: Core Software Prerequisites ---
# (Functions try_install_package, check_git, check_nvm_node_npm, check_python3_pip, check_vscode_cli are identical to v1.1.1)
try_install_package() {
    local pkg_name_human="$1"; local pkg_name_apt="$2"; local pkg_name_brew="$3"; local install_url="$4"
    if ! ask_yes_no "Attempt automatic installation of ${pkg_name_human}?"; then
        info "Skipping auto-install of ${pkg_name_human}. Manual install: ${install_url}"; return 1;
    fi
    if [[ "${OS_TYPE}" == "linux" ]] && command_exists apt-get; then
        info "Installing ${pkg_name_apt} via apt (sudo)..."
        if sudo apt-get update && sudo apt-get install -y "${pkg_name_apt}"; then success "${pkg_name_human} installed (apt)."; return 0;
        else error "${pkg_name_human} install failed (apt)."; fi
    elif ([[ "${OS_TYPE}" == "macos" ]] || [[ "${OS_TYPE}" == "linux" ]]) && command_exists brew; then
        info "Installing ${pkg_name_brew} via brew..."
        if brew install "${pkg_name_brew}"; then success "${pkg_name_human} installed (brew)."; return 0;
        else error "${pkg_name_human} install failed (brew)."; fi
    else warning "No supported package manager for ${pkg_name_human}."; fi
    info "Please install ${pkg_name_human} manually: ${install_url}"; return 1;
}
check_git() {
    info "Checking Git..."; if command_exists git; then success "Git installed ($(git --version | head -n1))."; return 0; fi
    warning "Git not found."; if try_install_package "Git" "git" "git" "https://git-scm.com/downloads"; then if command_exists git; then return 0; fi; fi
    error "Git is required. Exiting." "exit"; return 1;
}
check_nvm_node_npm() {
    info "Checking NVM (Node Version Manager)..."; export NVM_DIR="${HOME}/.nvm"; [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh";
    if ! command_exists nvm; then
        warning "NVM not found."; if ! ask_yes_no "Install NVM (recommended for Node.js)?"; then info "Skipping NVM. Manual Node.js needed."; return 1; fi
        info "Installing NVM..."; local nvm_v; nvm_v=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/');
        if [ -z "$nvm_v" ]; then nvm_v="v0.39.7"; fi; info "Using NVM ${nvm_v}";
        if curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_v}/install.sh" | bash; then
            export NVM_DIR="${HOME}/.nvm"; [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh";
            if command_exists nvm; then success "NVM installed. Source your shell profile or reopen terminal."; else error "NVM install script ran, but 'nvm' not found."; return 1; fi
        else error "NVM install script failed."; return 1; fi
    else success "NVM installed ($(nvm --version))."; fi
    info "Checking Node.js LTS (v${NODE_LTS_VERSION_MAJOR}.x)..."; local current_node_version; current_node_version=$(nvm current); local target_lts_prefix="v${NODE_LTS_VERSION_MAJOR}";
    if echo "$current_node_version" | grep -q -E "^${target_lts_prefix}\."; then success "Node.js $(node -v) (npm $(npm -v)) from ${target_lts_prefix}.x series is active.";
    else
        if [[ "$current_node_version" != "none" && "$current_node_version" != "system" ]]; then warning "Current Node.js ($current_node_version) not ${target_lts_prefix}.x series.";
        elif [[ "$current_node_version" == "system" ]]; then warning "System Node.js ($current_node_version - $(node -v 2>/dev/null || echo 'unknown')) active. NVM Node.js v${NODE_LTS_VERSION_MAJOR}.x preferred.";
        else warning "No Node.js version active via NVM."; fi
        local latest_installed_lts; latest_installed_lts=$(nvm ls --no-colors --no-alias "$target_lts_prefix" 2>/dev/null | grep -E "^\s*${target_lts_prefix}\." | awk '{print $1}' | sort -V | tail -n 1);
        if [ -n "$latest_installed_lts" ]; then info "Found installed Node.js ${target_lts_prefix}.x: ${latest_installed_lts}."; if ask_yes_no "Set ${latest_installed_lts} as current?"; then
                if nvm use "${latest_installed_lts}"; then success "Node.js $(node -v) (npm $(npm -v)) active."; else error "Failed to switch to ${latest_installed_lts}."; fi; fi; fi
        current_node_version=$(nvm current); if ! echo "$current_node_version" | grep -q -E "^${target_lts_prefix}\."; then
            warning "Node.js LTS ${target_lts_prefix}.x still not active."; if ask_yes_no "Install latest Node.js LTS ${target_lts_prefix}.x via NVM (and set default)?"; then
                info "Installing Node.js LTS ${target_lts_prefix}.x..."; if nvm install "${NODE_LTS_VERSION_MAJOR}"; then nvm alias default "${NODE_LTS_VERSION_MAJOR}"; success "Node.js $(node -v) (npm $(npm -v)) installed.";
                else error "Node.js LTS ${target_lts_prefix}.x install failed."; return 1; fi
            else info "Skipping Node.js LTS ${target_lts_prefix}.x install."; warning "Node.js ${target_lts_prefix}.x series recommended."; fi; fi; fi
    if ! command_exists node; then error "Node.js 'node' not found."; return 1; fi; if ! command_exists npm; then error "npm not found."; return 1; fi; return 0;
}
check_python3_pip() {
    info "Checking Python 3/pip..."; local py_exe="";
    if command_exists python3; then py_exe="python3"; elif command_exists python && python --version 2>&1 | grep -q "Python 3\."; then py_exe="python"; fi
    if [[ -n "$py_exe" ]]; then success "Python 3 found ($($py_exe --version 2>&1)).";
        if $py_exe -m pip --version >/dev/null 2>&1; then success "pip for $py_exe available ($($py_exe -m pip --version | awk '{print $2}'))."; return 0;
        else warning "pip for $py_exe not found."; if [[ "${OS_TYPE}" == "linux" ]] && command_exists apt-get; then
            if try_install_package "python3-pip" "python3-pip" "" "https://pip.pypa.io/en/stable/installation/"; then if $py_exe -m pip --version >/dev/null 2>&1; then return 0; fi; fi
            fi; error "pip for Python 3 required. Install manually."; return 1; fi
    else warning "Python 3 not found."; if try_install_package "Python 3" "python3 python3-pip" "python@3.9" "https://www.python.org/downloads/"; then if command_exists python3 || \
        (command_exists python && python --version 2>&1 | grep -q "Python 3\."); then check_python3_pip; return $?; fi; fi; error "Python 3 required. Exiting." "exit"; return 1; fi
}
check_vscode_cli() {
    info "Checking VS Code CLI ('code')..."; if command_exists code; then success "VS Code CLI 'code' available."; return 0; else
    warning "VS Code CLI 'code' not in PATH. If VS Code installed, add 'code' to PATH (Command Palette > 'Shell Command: Install code command in PATH')."; return 1; fi
}
# End Section 1

# --- Section 2 (Prompting Part) & Section 3: Git User Config & SSH Key for GitHub ---
# (Functions prompt_git_user_config, ensure_ssh_key_for_github are identical to v1.1.1)
prompt_git_user_config() {
    info "SECTION 2: Configuring Git User Name and Email..."
    echo "-----------------------------------------------------"
    info "This will be applied LOCALLY to each cloned G@FT.ai repository."
    local name_prompt_default=""; if [ -n "$GIT_USER_NAME_ENV_DEFAULT" ]; then name_prompt_default="$GIT_USER_NAME_ENV_DEFAULT"; elif [ -n "$(git config --global user.name || echo "")" ]; then name_prompt_default="$(git config --global user.name)"; fi
    if [ -n "$name_prompt_default" ]; then info "Suggested Git user.name: ${name_prompt_default}"; if ask_yes_no "Use this name?"; then GIT_USER_NAME="$name_prompt_default"; fi; fi
    if [ -z "$GIT_USER_NAME" ]; then while [ -z "$GIT_USER_NAME" ]; do read -r -p "Enter your Full Name (for Git commits): " GIT_USER_NAME; done; fi
    local email_prompt_default=""; if [ -n "$GIT_USER_EMAIL_ENV_DEFAULT" ]; then email_prompt_default="$GIT_USER_EMAIL_ENV_DEFAULT"; elif [ -n "$(git config --global user.email || echo "")" ]; then email_prompt_default="$(git config --global user.email)"; fi
    if [ -n "$email_prompt_default" ]; then info "Suggested Git user.email: ${email_prompt_default}"; if ask_yes_no "Use this email?"; then GIT_USER_EMAIL="$email_prompt_default"; fi; fi
    if [ -z "$GIT_USER_EMAIL" ]; then while [ -z "$GIT_USER_EMAIL" ]; do read -r -p "Enter Email (Git commits): " GIT_USER_EMAIL; if [[ ! "$GIT_USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then error "Invalid email."; GIT_USER_EMAIL=""; fi; done; fi
    echo "-----------------------------------------------------"
}
ensure_ssh_key_for_github() {
    info "SECTION 3: Checking SSH Key for GitHub Access..."
    echo "-----------------------------------------------------"
    local ssh_key_path_ed25519="${HOME}/.ssh/id_ed25519"; local public_key_path=""
    if [ -f "${ssh_key_path_ed25519}.pub" ]; then public_key_path="${ssh_key_path_ed25519}.pub"; success "Ed25519 SSH key found: ${public_key_path}";
    else local ssh_key_path_rsa="${HOME}/.ssh/id_rsa"; if [ -f "${ssh_key_path_rsa}.pub" ]; then public_key_path="${ssh_key_path_rsa}.pub"; warning "RSA SSH key found. Ed25519 preferred.";
        else warning "No SSH key found."; if ! ask_yes_no "Generate Ed25519 SSH key?"; then error "SSH key required. Exiting." "exit"; fi
            info "Generating Ed25519 SSH key..."; if [ -z "$GIT_USER_EMAIL" ]; then error "GIT_USER_EMAIL not set. Exiting." "exit"; fi
            if ssh-keygen -t ed25519 -C "${GIT_USER_EMAIL}" -f "${ssh_key_path_ed25519}" -N ""; then success "Generated: ${ssh_key_path_ed25519}"; public_key_path="${ssh_key_path_ed25519}.pub";
            else error "SSH keygen failed. Exiting." "exit"; fi; fi; fi
    info "Add public key to GitHub: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account"
    echo -e "\n${COLOR_GREEN}Public key (${public_key_path}):\n$(cat "${public_key_path}")${COLOR_RESET}\n"
    if ! ask_yes_no "Have you added this key to GitHub & authorized it?"; then error "Add key to GitHub. Exiting." "exit"; fi
    info "Testing SSH to GitHub..."; if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then success "SSH to GitHub OK!";
    else warning "SSH to GitHub failed."; ssh -T git@github.com; error "Ensure key is correct on GitHub."; if ! ask_yes_no "Proceed anyway (NOT RECOMMENDED)?"; then error "Exiting." "exit"; fi; fi
    echo "-----------------------------------------------------"; return 0
}
# End Section 2 & 3

# --- Section 4: Create Workspace Directories ---
# (Function create_workspace_directories is identical to v1.1.1)
create_workspace_directories() {
    info "SECTION 4: Creating Workspace Directory Structure..."
    echo "-----------------------------------------------------"
    if [ ! -d "${GFTAI_WORKSPACE_PARENT_DIR}" ]; then info "Parent dir '${GFTAI_WORKSPACE_PARENT_DIR}' not found."; if ask_yes_no "Create it?"; then
            if mkdir -p "${GFTAI_WORKSPACE_PARENT_DIR}"; then success "Created: ${GFTAI_WORKSPACE_PARENT_DIR}"; else error "Failed: ${GFTAI_WORKSPACE_PARENT_DIR}." "exit"; fi
        else error "Parent dir required. Exiting." "exit"; fi; else success "Parent dir exists: ${GFTAI_WORKSPACE_PARENT_DIR}"; fi
    if [ ! -d "${GFTAI_PROJECTS_DIR}" ]; then info "Projects dir '${GFTAI_PROJECTS_DIR}' not found. Creating...";
        if mkdir -p "${GFTAI_PROJECTS_DIR}"; then success "Created: ${GFTAI_PROJECTS_DIR}"; else error "Failed: ${GFTAI_PROJECTS_DIR}." "exit"; fi
    else success "Projects dir exists: ${GFTAI_PROJECTS_DIR}"; fi
    echo "-----------------------------------------------------"; return 0
}
# End Section 4

# --- Section 5: Clone Studio Repositories & Apply Local Git Config ---
# (Functions apply_local_git_config and clone_studio_repositories are identical to v1.1.1)
apply_local_git_config() {
    local repo_path="$1"; local current_repo_name; current_repo_name=$(basename "$repo_path")
    if [ -d "${repo_path}/.git" ]; then info "Configuring local Git for ${current_repo_name}...";
        (cd "${repo_path}" && git config --local user.name "${GIT_USER_NAME}" && git config --local user.email "${GIT_USER_EMAIL}" && success "Local Git config set for ${current_repo_name}") || error "Failed local Git config for ${current_repo_name}"; fi
}
clone_studio_repositories() {
    info "SECTION 5: Cloning Studio Repositories..."; echo "-----------------------------------------------------"
    info "Target: ${GFTAI_PROJECTS_DIR}. Cloning via SSH."; if [ -z "${GIT_USER_NAME}" ] || [ -z "${GIT_USER_EMAIL}" ]; then error "Git user info not set." "exit"; fi
    local overall_s=true; local cl_c=0; local pu_c=0; local sk_pu_c=0; local fa_cl_c=0; local fa_pu_c=0
    for repo_name_lv in "${GFTAI_REPOS[@]}"; do
        local repo_url="git@github.com:${GFTAI_ORG_NAME}/${repo_name_lv}.git"; local target_rp="${GFTAI_PROJECTS_DIR}/${repo_name_lv}"
        echo; info "Processing: ${GFTAI_ORG_NAME}/${repo_name_lv}"
        if [ -d "${target_rp}/.git" ]; then success "'${repo_name_lv}' cloned."; if ask_yes_no "Pull '${repo_name_lv}'?" "no"; then info "Pulling ${repo_name_lv}...";
                if (cd "${target_rp}" && git pull --ff-only); then success "Pulled ${repo_name_lv}."; pu_c=$((pu_c + 1)); else warning "Pull failed for ${repo_name_lv}."; fa_pu_c=$((fa_pu_c + 1)); fi
            else info "Skipped pull for ${repo_name_lv}."; sk_pu_c=$((sk_pu_c + 1)); fi
        elif [ -d "${target_rp}" ]; then warning "Dir '${target_rp}' exists but not Git repo. Skipping."; fa_cl_c=$((fa_cl_c + 1)); overall_s=false;
        else info "Cloning ${repo_url}..."; if git clone "${repo_url}" "${target_rp}"; then success "Cloned '${repo_name_lv}'."; cl_c=$((cl_c + 1));
            else error "Clone failed: ${GFTAI_ORG_NAME}/${repo_name_lv}."; fa_cl_c=$((fa_cl_c + 1)); overall_s=false; fi; fi
        if [ -d "${target_rp}/.git" ]; then apply_local_git_config "${target_rp}"; fi
    done
    echo; info "Summary: New: ${cl_c}, Pulled: ${pu_c}, SkipPull: ${sk_pu_c}, FailClone: ${fa_cl_c}, FailPull: ${fa_pu_c}"
    if [ "$overall_s" = false ] || [ "$fa_cl_c" -gt 0 ]; then warning "Repo issues occurred."; else success "Repos processed."; fi
    echo "-----------------------------------------------------"; return 0
}
# End Section 5

# --- Section 6: Create VS Code Workspace File ---
# (Function create_vscode_workspace_file is identical to v1.1.1)
create_vscode_workspace_file() {
    info "SECTION 6: Creating VS Code Workspace File..."; echo "-----------------------------------------------------"
    if ! command_exists code; then warning "VS Code CLI 'code' not found. Skipping."; return 1; fi
    local vscode_ws_c='{\n\t"folders": [\n'; local first_f=true; info "Generating list for: ${GFTAI_VSCODE_WORKSPACE_FILE}"
    for repo_name_lv in "${GFTAI_REPOS[@]}"; do
        local rel_rp="${GFTAI_PROJECTS_DIR_NAME}/${repo_name_lv}"; local actual_rp="${GFTAI_PROJECTS_DIR}/${repo_name_lv}"
        if [ -d "${actual_rp}/.git" ]; then if [ "$first_f" = true ]; then first_f=false; else vscode_ws_c+=',\n'; fi
            vscode_ws_c+="\t\t{\n\t\t\t\"path\": \"${rel_rp}\"\n\t\t}"; fi; done
    vscode_ws_c+='\n\t],\n\t"settings": {\n\t\t"workbench.colorTheme": "Default Dark+",\n\t\t"files.autoSave": "afterDelay",\n\t\t"editor.minimap.enabled": false,\n\t\t"editor.renderWhitespace": "boundary",\n\t\t"files.trimTrailingWhitespace": true,\n\t\t"files.insertFinalNewline": true,\n\t\t"workbench.startupEditor": "none"\n\t}\n}\n'
    info "Writing to: ${GFTAI_VSCODE_WORKSPACE_FILE}"; if printf "%b" "${vscode_ws_c}" > "${GFTAI_VSCODE_WORKSPACE_FILE}"; then success "Workspace file created.";
    else error "Failed to create workspace file."; return 1; fi; echo "-----------------------------------------------------"; return 0
}
# End Section 6

# --- Section 7: Install Recommended VS Code Extensions ---
# (Function install_vscode_extensions is identical to v1.1.1)
install_vscode_extensions() {
    info "SECTION 7: Installing VS Code Extensions..."; echo "-----------------------------------------------------"
    if ! command_exists code; then warning "VS Code CLI 'code' not found. Skipping."; return 1; fi
    info "Will check/install extensions:"; for ext_id_d in "${VSCODE_COMMON_EXTENSIONS[@]}"; do echo "  - ${ext_id_d}"; done; echo
    if ! ask_yes_no "Proceed with extension check/install?"; then info "Skipping extension install."; echo "-----------------------------------------------------"; return 0; fi
    local inst_c=0; local alr_c=0; local fail_c=0; local curr_exts; curr_exts=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if [ $? -ne 0 ]; then warning "Could not list extensions. Will try to install all."; curr_exts=""; fi
    for ext_id in "${VSCODE_COMMON_EXTENSIONS[@]}"; do local ext_id_lc; ext_id_lc=$(echo "${ext_id}" | tr '[:upper:]' '[:lower:]')
        if echo "${curr_exts}" | grep -Fxq "${ext_id_lc}"; then success "'${ext_id}' already installed."; alr_c=$((alr_c + 1));
        else info "Installing '${ext_id}'..."; if code --install-extension "${ext_id}" --force; then success "Installed '${ext_id}'."; inst_c=$((inst_c + 1));
            else error "Failed to install '${ext_id}'."; fail_c=$((fail_c + 1)); fi; fi; done
    info "Ext summary: New: ${inst_c}, Present: ${alr_c}, Failed: ${fail_c}"; if [ "${fail_c}" -gt 0 ]; then warning "Some extensions failed."; fi
    info "Restart VS Code for changes to take effect."; echo "-----------------------------------------------------"; return 0
}
# End Section 7

# --- Main Script Logic ---
main() {
    load_env_file # Load .env first to override defaults

    info "Starting G@FT.ai Onboarding Script (v1.1.2)..." # Updated version
    info "This script will guide you through setting up your G@FT.ai workspace."

    # CORRECTED Initial Configuration Display:
    echo # Blank line for separation
    info "Initial configurations (from defaults and/or .env file):"
    info "  GitHub Organization Name:        ${COLOR_GREEN}${GFTAI_ORG_NAME}${COLOR_RESET}"
    info "  Workspace Parent Directory:      ${COLOR_GREEN}${GFTAI_WORKSPACE_PARENT_DIR}${COLOR_RESET}"
    info "  Projects SubDirectory Name:      ${COLOR_GREEN}${GFTAI_PROJECTS_DIR_NAME}${COLOR_RESET}"
    info "  Effective Projects Directory:    ${COLOR_GREEN}${GFTAI_PROJECTS_DIR}${COLOR_RESET}"
    info "  VS Code Workspace Filename:    ${COLOR_GREEN}${GFTAI_VSCODE_WORKSPACE_FILENAME}${COLOR_RESET}"
    info "  Effective VS Code Workspace File: ${COLOR_GREEN}${GFTAI_VSCODE_WORKSPACE_FILE}${COLOR_RESET}"
    info "  Suggested Git User Name (from .env): ${COLOR_GREEN}${GIT_USER_NAME_ENV_DEFAULT:-not set in .env}${COLOR_RESET}"
    info "  Suggested Git User Email (from .env):${COLOR_GREEN}${GIT_USER_EMAIL_ENV_DEFAULT:-not set in .env}${COLOR_RESET}"
    echo # Blank line

    if ! ask_yes_no "Do you wish to proceed with the onboarding process using these base settings (you will confirm Git name/email next)?"; then
        info "Onboarding process aborted by the user. You can edit the .env file to customize settings."; exit 0;
    fi
    echo

    # Section 1: Core Software Prerequisites
    info "SECTION 1: Core Software Prerequisites..."
    echo "-----------------------------------------------------"
    local critical_prereq_ok=true
    if ! check_git; then critical_prereq_ok=false; fi
    # NVM/Node/Python are important but script might proceed with warnings if they fail, Git is critical.
    check_nvm_node_npm
    check_python3_pip
    if ! $critical_prereq_ok; then error "Critical software (Git) setup failed. Exiting." "exit"; fi

    VSCODE_CLI_AVAILABLE=true # Assume true, check_vscode_cli will set to false if needed
    if ! check_vscode_cli; then VSCODE_CLI_AVAILABLE=false; fi
    success "Section 1 checks completed."
    echo "-----------------------------------------------------"

    # Section 2 (Prompting Part) & Section 3: Git User Config & SSH Key for GitHub
    # prompt_git_user_config will use GIT_USER_NAME_ENV_DEFAULT and GIT_USER_EMAIL_ENV_DEFAULT as primary suggestions
    prompt_git_user_config
    if ! ensure_ssh_key_for_github; then error "SSH Key setup for GitHub failed. This is critical for cloning. Exiting." "exit"; fi

    # Confirm all final configurations (including Git user name/email just entered)
    confirm_configurations

    # Section 4: Create Workspace Directories
    if ! create_workspace_directories; then error "Workspace directory creation failed. Exiting." "exit"; fi

    # Section 5: Clone Studio Repositories (and apply local Git config)
    clone_studio_repositories

    # Section 6: Create VS Code Workspace File
    if [ "$VSCODE_CLI_AVAILABLE" = true ]; then
        create_vscode_workspace_file
    else
        info "Skipping VS Code Workspace file creation as 'code' CLI is not available."
    fi

    # Section 7: Install VS Code Extensions
    if [ "$VSCODE_CLI_AVAILABLE" = true ]; then
        install_vscode_extensions
    else
        info "Skipping VS Code Extension installation as 'code' CLI is not available."
    fi

    # Final step: Attempt to open VS Code with the new workspace
    if [ "$VSCODE_CLI_AVAILABLE" = true ] && [ -f "${GFTAI_VSCODE_WORKSPACE_FILE}" ]; then
        info "Attempting to open the new workspace in VS Code..."
        if ask_yes_no "Do you want to try opening VS Code with the '${GFTAI_VSCODE_WORKSPACE_FILE}' workspace now?"; then
            if code "${GFTAI_VSCODE_WORKSPACE_FILE}"; then
                success "VS Code launch command issued for the workspace."
            else
                warning "Failed to launch VS Code automatically. Please open it manually using the .code-workspace file."
            fi
        else
            info "You can open the workspace later with: code \"${GFTAI_VSCODE_WORKSPACE_FILE}\""
        fi
    elif [ "$VSCODE_CLI_AVAILABLE" = false ]; then
        info "VS Code CLI 'code' was not found. Please open VS Code manually."
        info "If the workspace file was intended to be created, check for errors and find it at: ${GFTAI_VSCODE_WORKSPACE_FILE}"
    fi

    echo
    success "####################################################################"
    success "# G@FT.ai Developer Environment Onboarding Script has completed!   #"
    success "####################################################################"
    info "IMPORTANT NEXT STEPS & REMINDERS:"
    info "1. If NVM was installed/updated, CLOSE and REOPEN your terminal, or source your shell profile (e.g., 'source ~/.bashrc' or 'source ~/.zshrc')."
    info "2. If VS Code extensions were newly installed, you might need to RELOAD or RESTART VS Code."
    info "3. Your new G@FT.ai studio workspace is configured at: ${GFTAI_VSCODE_WORKSPACE_FILE}"
    info "   Open it with VS Code if it didn't open automatically."
    info "4. If you generated a new SSH key, ensure it's authorized for any specific repositories if needed (beyond just being added to your GitHub account)."
    info "5. Review any WARNING or ERROR messages above for manual follow-up."
    echo
}

# Run the main function if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
