#!/usr/bin/env bash

# G@FT.ai Studio - Developer Onboarding Script
# Version: 1.3.2 (Full repo clone, pre-commit install & hook setup, Cline VSCode ext, .env example refined)
# Maintainer: Camille (Gem AB - Automation Specialist)
# SSoT: gcd-onboarding-scripts/onboarding/gftai_onboarding.sh 
# Based on previous version: 1.3.1

# --- Configuration & Globals (Defaults) ---
readonly COLOR_BLUE="\033[1;34m"; readonly COLOR_GREEN="\033[1;32m"; readonly COLOR_RED="\033[1;31m";
readonly COLOR_YELLOW="\033[1;33m"; readonly COLOR_RESET="\033[0m";

GFTAI_ORG_NAME_DEFAULT="GenCr-ft"
GFTAI_WORKSPACE_PARENT_DIR_DEFAULT="${HOME}/gftai_studio_workspace" 
GFTAI_PROJECTS_DIR_NAME_DEFAULT="" 
GFTAI_VSCODE_WORKSPACE_FILENAME_DEFAULT="${GFTAI_ORG_NAME_DEFAULT}.code-workspace"
GIT_USER_NAME_ENV_DEFAULT=""
GIT_USER_EMAIL_ENV_DEFAULT=""
GIT_DEFAULT_BRANCH_NAME_ENV_DEFAULT="main" 
AUTO_INSTALL_TOOLS_DEFAULT=true
AUTO_GENERATE_SSH_KEY_DEFAULT=true
AUTO_ADD_SSH_KEY_TO_GITHUB_DEFAULT=true
AUTO_CLONE_REPOS_DEFAULT=true 
AUTO_CREATE_WORKSPACE_DEFAULT=true
AUTO_INSTALL_VSCODE_EXTENSIONS_DEFAULT=true
AUTO_OPEN_VSCODE_DEFAULT=true

# Full list of repositories to clone by default, based on Lug's provided list
# Excluding .github and .github-private (special GitHub repos).
# 'gencraft-operations' name to be clarified/migrated per ADR-001 later if needed.
GFTAI_REPOS_TO_CLONE_DEFAULT=(
    "gcp-aethel-architecture"        
    "gcs-devops-standards"         
    "gct-repo-template-standard"   
    "gencraft-iac"                 # Using current name as per Lug's instruction
    "gcp-aethel-docs-external"     
    "gcp-aethel-qa"                
    "gcp-aethel-backlog"           
    "gcp-aethel-docs-req"          
    "gcs-project-management"       
    "gcp-aethel-docs-gdd"          
    "gcs-plt-architecture"         
    "gcs-plt-gemop"                
    "gcs-plt-gembp"                
    "gcs-plt-crewwkf"              
    "gcs-security-core"            
    "gcs-plt-backlog"              
    "gcs-plt-assets"               
    "gcs-plt-tools"                
    "gcs-global-assets"            
    "gcs-studio-legal"             
    "gcl-voxel-engine"             
    "gcl-ui-components"            
    "gct-service-template-py"      
    "gct-repo-template-backlog"    
    "gcd-shared-actions"           
    "gcd-onboarding-scripts"       # This script's home repository
    "gcs-plt-docs-req"             
    "gci-k8s-cluster-main"         
    "gci-aws-foundations"          
    "gcp-aethel-assets-char"       
    "gcp-aethel-assets-audio"      
    "gcd-backup-utilities"         
    "gencraft-operations"          # Name to be clarified/migrated later if needed
    "gcs-studio-handbook"          
    "gcl-api-contracts"            
    "gcl-srv-persistence"          
    "gcl-srv-authentication"       
    "gcp-aethel-pcg"               
    "gcp-aethel-server"            
    "gcp-aethel-client"            
)

VSCODE_EXTENSIONS_TO_INSTALL=(
    "hashicorp.terraform"      
    "redhat.vscode-yaml"       
    "timonwong.shellcheck"     
    "ms-vscode.powershell"     
    "ms-python.python"         
    "ms-python.flake8"         
    "ms-python.black-formatter"
    "ms-azuretools.vscode-docker"
    "GitHub.copilot"           
    "GitHub.copilot-chat"      
    "eamodio.gitlens"          
    "yzhang.markdown-all-in-one"
    "davidanson.vscode-markdownlint"
    "bierner.markdown-preview-github-styles"
    "donjayamanne.githistory"
    "mhutchie.git-graph"       
    "EditorConfig.EditorConfig"
    "mutantdino.resourcemonitor"
    "ms-vscode.cpptools"       
    "usernamehw.errorlens"     
    "wayou.vscode-todo-highlight"
    "VisualStudioExptTeam.intellicode-api-usage-examples" 
    "github.vscode-pull-request-github"
    "ms-dotnettools.csdevkit" 
    "llvm-vs-code-extensions.vscode-clangd" 
    "saoudrizwan.claude-dev" # Added Cline as per Lug's request
)

# --- Global Variables (initialized in main) ---
SCRIPT_DIR=""
OS_TYPE=""
ENV_FILE_LOADED=false
GFTAI_ORG_NAME=""
GFTAI_WORKSPACE_PARENT_DIR=""
GFTAI_PROJECTS_DIR_NAME="" # Remains empty
GFTAI_VSCODE_WORKSPACE_FILENAME=""
GIT_USER_NAME=""
GIT_USER_EMAIL=""
GIT_DEFAULT_BRANCH_NAME=""
declare -a GFTAI_REPOS_TO_CLONE=()
AUTO_INSTALL_TOOLS=true
AUTO_GENERATE_SSH_KEY=true
AUTO_ADD_SSH_KEY_TO_GITHUB=true
AUTO_CLONE_REPOS=true
AUTO_CREATE_WORKSPACE=true
AUTO_INSTALL_VSCODE_EXTENSIONS=true
AUTO_OPEN_VSCODE=true
NVM_DIR="" 
NVM_INSTALLED_NOW=false 
PYENV_ROOT=""
PYENV_INSTALLED_NOW=false
VSCODE_CLI_AVAILABLE=false 
VSCODE_WORKSPACE_CREATED_OR_UPDATED=false
declare -g GH_AUTH_OK_FOR_ORG=false # NEW global flag for gh auth status

# --- Load .env file ---
load_env_file() {
    local env_file_path="${SCRIPT_DIR}/.env"
    if [ -f "$env_file_path" ]; then
        info "Loading environment variables from ${env_file_path}..."
        set -o allexport; source "$env_file_path"; set +o allexport
        ENV_FILE_LOADED=true
    else
        info "No .env file found at ${env_file_path}. Using default configurations."
        ENV_FILE_LOADED=false
    fi

    GFTAI_ORG_NAME="${GFTAI_ORG_NAME_OVERRIDE:-$GFTAI_ORG_NAME_DEFAULT}"
    GFTAI_WORKSPACE_PARENT_DIR="${GFTAI_WORKSPACE_PARENT_DIR_OVERRIDE:-$GFTAI_WORKSPACE_PARENT_DIR_DEFAULT}"
    GFTAI_PROJECTS_DIR_NAME="${GFTAI_PROJECTS_DIR_NAME_OVERRIDE:-$GFTAI_PROJECTS_DIR_NAME_DEFAULT}" # Should remain empty
    GFTAI_VSCODE_WORKSPACE_FILENAME="${GFTAI_VSCODE_WORKSPACE_FILENAME_OVERRIDE:-$GFTAI_VSCODE_WORKSPACE_FILENAME_DEFAULT}"
    GIT_USER_NAME="${GIT_USER_NAME_OVERRIDE:-$GIT_USER_NAME_ENV_DEFAULT}"
    GIT_USER_EMAIL="${GIT_USER_EMAIL_OVERRIDE:-$GIT_USER_EMAIL_ENV_DEFAULT}"
    GIT_DEFAULT_BRANCH_NAME="${GIT_DEFAULT_BRANCH_NAME_OVERRIDE:-$GIT_DEFAULT_BRANCH_NAME_ENV_DEFAULT}"

    # Convert AUTO_ flags to boolean true/false
    local auto_flags_vars=("AUTO_INSTALL_TOOLS" "AUTO_GENERATE_SSH_KEY" "AUTO_ADD_SSH_KEY_TO_GITHUB" "AUTO_CLONE_REPOS" "AUTO_CREATE_WORKSPACE" "AUTO_INSTALL_VSCODE_EXTENSIONS" "AUTO_OPEN_VSCODE")
    local default_flag_value_var_name
    local override_flag_value_var_name
    for flag_var in "${auto_flags_vars[@]}"; do
        default_flag_value_var_name="${flag_var}_DEFAULT"
        override_flag_value_var_name="${flag_var}_OVERRIDE"
        # Dynamically get the value of the override variable and default variable
        # This requires indirect expansion
        eval "current_value=\"\${${override_flag_value_var_name}:-\$${default_flag_value_var_name}}\""
        if [[ "$current_value" =~ ^(true|yes|1)$ ]]; then
            eval "$flag_var=true"
        else
            eval "$flag_var=false"
        fi
    done

    if [[ -n "$GFTAI_REPOS_TO_CLONE_OVERRIDE" ]]; then
        read -r -a GFTAI_REPOS_TO_CLONE <<< "$GFTAI_REPOS_TO_CLONE_OVERRIDE"
        info "Overriding default repository list with .env configuration for GFTAI_REPOS_TO_CLONE."
    else
        GFTAI_REPOS_TO_CLONE=("${GFTAI_REPOS_TO_CLONE_DEFAULT[@]}")
    fi
} # logic adapted and improved

# --- Utility Functions (Copied from validate_gft_devops_environment.sh v1.5.0 for robustness) ---
FAIL_COUNT_ONBOARDING=0 
WARN_COUNT_ONBOARDING=0

_onboarding_print_status() {
    local message="$1"
    local status="$2"
    local prefix
    case "$status" in
        OK)       prefix="[${COLOR_GREEN}OK${COLOR_RESET}]     ";;
        ERROR)    prefix="[${COLOR_RED}ERROR${COLOR_RESET}]  "; ((FAIL_COUNT_ONBOARDING++));; 
        WARN)     prefix="[${COLOR_YELLOW}WARN${COLOR_RESET}]   "; ((WARN_COUNT_ONBOARDING++));;
        INFO)     prefix="[${COLOR_CYAN}INFO${COLOR_RESET}]   ";;
        STEP)     prefix="[${COLOR_BLUE}STEP${COLOR_RESET}]   ";; 
        ACTION)   prefix="${COLOR_YELLOW}ACTION${COLOR_RESET}: ";; 
        SUCCESS)  prefix="[${COLOR_GREEN}SUCCESS${COLOR_RESET}]";; 
        *)        prefix="[????]   ";;
    esac
    echo -e "$prefix$message"
}

success() { _onboarding_print_status "$1" "SUCCESS"; }
error() { _onboarding_print_status "$1" "ERROR"; } 
warning() { _onboarding_print_status "$1" "WARN"; } 
info() { _onboarding_print_status "$1" "INFO"; }
step_info() { _onboarding_print_status "$1" "STEP"; }

command_exists() { command -v "$1" &>/dev/null; }
ensure_dir() { 
    if [ ! -d "$1" ]; then 
        if mkdir -p "$1"; then
            info "Created directory: $1"
        else
            error "Failed to create directory: $1 ! Please check permissions or path."
        fi
    fi 
}

confirm_action() {
    local question="$1"
    local default_answer="${2:-yes}" 
    local prompt_options="[Y/n]"
    if [[ "$default_answer" =~ ^(no|n|N)$ ]]; then prompt_options="[y/N]"; fi

    while true; do
        _onboarding_print_status "$question $prompt_options " "ACTION" 
        read -r answer 
        answer="${answer:-$default_answer}"
        case "$answer" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) error "Invalid response. Please answer 'yes' or 'no'." ;; 
        esac
    done
}

# --- Tool Installation Functions ---
check_and_install_homebrew() {
    step_info "A1: Checking/Installing Homebrew (for macOS)..."
    if [[ "$OS_TYPE" == "Darwin" ]]; then 
        if ! command_exists brew; then
            if $AUTO_INSTALL_TOOLS || confirm_action "Homebrew not found. Install it now?"; then
                info "Installing Homebrew..."
                if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                    success "Homebrew installed successfully."
                    info "Ensuring Homebrew is in PATH for this session..."
                    if [ -x "/opt/homebrew/bin/brew" ]; then 
                        export PATH="/opt/homebrew/bin:$PATH"
                        info "Homebrew (Apple Silicon) added to PATH for this session."
                    elif [ -x "/usr/local/bin/brew" ]; then 
                         export PATH="/usr/local/bin:$PATH"
                         info "Homebrew (Intel Mac) added to PATH for this session."
                    fi
                    info "You might need to restart your terminal or source your shell profile for permanent effect."
                    NVM_INSTALLED_NOW=true # Re-using this flag as a generic "core dep installed"
                else
                    error "Failed to install Homebrew."
                fi
            else
                warning "Skipping Homebrew installation. Some tools may not be installable automatically via script."
            fi
        else
            success "Homebrew found: $(brew --version 2>/dev/null | head -n1 || echo "version not parsable")"
        fi
    else
        info "Not macOS. Skipping Homebrew check."
    fi
    echo "-------------------------------------------------------------------"
} 

check_and_install_git() {
    step_info "A2: Checking/Installing Git..."
    local git_ok=false
    if ! command_exists git; then
        if $AUTO_INSTALL_TOOLS || confirm_action "Git not found. Install it now?"; then
            info "Attempting to install Git..."
            case "$OS_TYPE" in
                Linux) 
                    if sudo apt update -qq && sudo apt install -y -qq git; then git_ok=true; else error "apt install git failed."; fi ;;
                Darwin) 
                    if command_exists brew; then 
                        if brew install git; then git_ok=true; else error "brew install git failed."; fi
                    else error "Brew not found, cannot install Git via brew."; fi ;;
                *) error "Unsupported OS for automatic Git installation: $OS_TYPE" ;;
            esac
            if $git_ok; then success "Git installed successfully: $(git --version 2>/dev/null | head -n1)"; else error "Failed to install Git."; fi
        else
            warning "Skipping Git installation. Git is essential for development."
        fi
    else
        success "Git found: $(git --version 2>/dev/null | head -n1)"
        git_ok=true 
    fi
    echo "-------------------------------------------------------------------"
} 



check_and_install_nvm_node() {
    step_info "A4: Checking/Installing NVM, Node.js, npm, and global Node packages (commitlint)..."
    if $AUTO_INSTALL_TOOLS || confirm_action "Node.js (via NVM is recommended) & core Node packages. Install/Verify?"; then
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}" 
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            info "NVM already installed. Sourcing NVM..."
            # shellcheck source=/dev/null
            source "$NVM_DIR/nvm.sh"
            if ! command_exists nvm; then 
                 warning "Sourcing NVM did not make 'nvm' command available. Manual shell restart/profile source might be needed."
            else
                success "NVM sourced."
            fi
        else
            info "Installing NVM (Node Version Manager)..."
            if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; then 
                success "NVM installation script downloaded and executed."
                export NVM_DIR="$HOME/.nvm" 
                # shellcheck source=/dev/null
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
                NVM_INSTALLED_NOW=true 
            else
                error "Failed to download or execute NVM installation script."
            fi
        fi

        if command_exists nvm; then
            info "Using NVM to install/verify Node.js LTS..."
            if nvm install --lts && nvm use --lts && nvm alias default lts/*; then 
                success "Node.js LTS installed and set as default via NVM."
                success "Node version: $(node --version 2>/dev/null || echo "N/A")"
                success "npm version: $(npm --version 2>/dev/null || echo "N/A")"

                info "Installing/Updating global Node packages: @commitlint/cli, @commitlint/config-conventional, conventional-changelog-cli..."
                if npm install -g @commitlint/cli @commitlint/config-conventional conventional-changelog-cli; then
                    success "commitlint and conventional-changelog-cli installed/updated globally via npm."
                else
                    error "Failed to install/update commitlint or conventional-changelog-cli globally via npm."
                fi
            else
                error "Failed to install Node.js LTS using NVM."
                if $NVM_INSTALLED_NOW; then info "NVM was just installed. Please CLOSE and REOPEN your terminal, then re-run relevant parts of the script or install Node.js LTS manually using: nvm install --lts"; fi
            fi
        elif [ "$NVM_INSTALLED_NOW" != true ]; then
             warning "NVM command not available. Skipping Node.js LTS installation via NVM."
        elif $NVM_INSTALLED_NOW; then 
             info "NVM was just installed. A terminal restart is likely needed to use the 'nvm' command."
        fi
    else
        warning "Skipping NVM/Node.js and global Node packages installation."
    fi
    echo "-------------------------------------------------------------------"
} 

check_and_install_docker() {
     step_info "A6: Checking/Installing Docker..."
    # ... (Logic from v1.3.1 - using official Docker install script for Linux) ...
    local docker_ok=false
    if ! command_exists docker; then
        if $AUTO_INSTALL_TOOLS || confirm_action "Docker not found. Attempt to install Docker Engine and Docker Compose?"; then
            info "Attempting to install Docker..."
            case "$OS_TYPE" in
                Linux)
                    info "Following official Docker CE for Ubuntu installation steps."
                    if ! command_exists curl; then sudo apt update -qq && sudo apt install -y -qq curl || { error "curl is required to install Docker."; return 1; }; fi
                    if ! command_exists gpg; then sudo apt update -qq && sudo apt install -y -qq gpg || { error "gpg is required to install Docker."; return 1; }; fi
                    
                    sudo install -m 0755 -d /etc/apt/keyrings
                    if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
                        sudo chmod a+r /etc/apt/keyrings/docker.gpg
                        echo \
                          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                        sudo apt-get update -qq
                        if sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                            success "Docker Engine and Compose plugin installed successfully."
                            docker_ok=true
                        else
                            error "Failed to install Docker Engine packages."
                        fi
                    else
                        error "Failed to download or dearmor Docker GPG key."
                    fi
                    ;;
                Darwin)
                    info "For macOS, please install Docker Desktop manually from https://www.docker.com/products/docker-desktop/"
                    warning "Skipping automatic Docker installation on macOS."
                    ;;
                *) error "Unsupported OS for automatic Docker installation: $OS_TYPE" ;;
            esac
        else
            warning "Skipping Docker installation."
        fi
    else
        success "Docker found: $(docker --version 2>/dev/null || echo "version not parsable")"
        docker_ok=true 
    fi

    if $docker_ok; then
        if ! docker ps > /dev/null 2>&1; then
            if [[ "$OS_TYPE" == "Linux" ]] && ! groups "${USER}" | grep -q '\bdocker\b'; then
                warning "Docker command found, but user '${USER}' may not be in the 'docker' group."
                if confirm_action "Add user '${USER}' to the 'docker' group? (Requires sudo and logout/login to take effect)"; then
                    if sudo usermod -aG docker "${USER}"; then
                        success "User ${USER} added to docker group. Please LOG OUT and LOG BACK IN for this to take effect."
                    else
                        error "Failed to add user to docker group."
                    fi
                fi
            else 
                 warning "Docker command found, but Docker daemon does not seem to be running or responsive."
            fi
            info "Ensure Docker Desktop is running (macOS/Windows) or Docker service is active and user has permissions (Linux)."
        else
            success "Docker daemon is responsive."
        fi
    fi
    echo "-------------------------------------------------------------------"
} 

# ensure_gh_authenticated (Identique à la v1.3.4)
ensure_gh_authenticated() {
    info "Verifying GitHub CLI authentication and access to organization '${GFTAI_ORG_NAME}'..."
    local gh_user 

    if ! command_exists gh ; then
        error "'gh' command not found. Cannot perform authentication check or operations."
        GH_AUTH_OK_FOR_ORG=false
        return 1
    fi

    if ! gh auth status -h github.com >/dev/null 2>&1; then
        warning "gh is not authenticated for github.com."
        if $AUTO_INSTALL_TOOLS || confirm_action "Do you want to attempt 'gh auth login' now? This is required for studio operations."; then
            info "Please follow the prompts from 'gh auth login'."
            info "Recommended scopes to select (use spacebar to select/deselect, Enter to confirm):"
            info "  [X] repo          (Full control of private repositories)"
            info "  [X] admin:org     (Full control of organizations and their teams, members, and projects)"
            info "  [X] workflow      (Manage GitHub Actions workflows)"
            info "  [X] read:user     (Grants read access to user profile data)"
            info "  [X] write:public_key (Allows adding SSH public keys)"
            echo 
            local gh_auth_method_pref="web"; # Default to web as it's generally easier
            _onboarding_print_status "How would you like to authenticate GitHub CLI? (Type 'web' for Web Browser/HTTPS, or 'ssh' for SSH key) [default: web]: " "ACTION"
            read -r gh_auth_input
            gh_auth_method_choice="${gh_auth_input:-web}" 
            gh_auth_method_choice=$(echo "$gh_auth_method_choice" | tr '[:upper:]' '[:lower:]') 
            if [[ "$gh_auth_method_choice" != "web" && "$gh_auth_method_choice" != "ssh" ]]; then
                warning "Invalid selection, defaulting to 'web' authentication."
                gh_auth_method_choice="web"
            fi
            info "Selected authentication method: ${gh_auth_method_choice^^}"

            if gh auth login --hostname github.com --git-protocol "$gh_auth_method_choice" --web --scopes repo,admin:org,workflow,read:user,write:public_key; then
                success "'gh auth login' process completed by 'gh'."
            else
                error "'gh auth login' process reported an error or was aborted by you."
                info "If 'gh' could not automatically open your web browser (common in WSL without wslu),"
                info "it should display a one-time code and a URL (like https://github.com/login/device)."
                info "You NEED TO MANUALLY open that URL in your Windows browser and enter the code."
                info "If you encountered a 'slow_down' error, please wait a few minutes before trying 'gh auth login' again manually from your terminal."
                GH_AUTH_OK_FOR_ORG=false
                return 1 
            fi
        else
            warning "Skipping 'gh auth login'. Some operations might fail."
            GH_AUTH_OK_FOR_ORG=false
            return 1 
        fi
    fi

    gh_user=$(gh api user --jq .login 2>/dev/null || echo "unknown_user (or gh not fully authenticated)")
    info "gh authenticated to github.com as '${gh_user}'. Checking access to organization '${GFTAI_ORG_NAME}'..."

    if gh repo list "${GFTAI_ORG_NAME}" --limit 1 --json name >/dev/null 2>&1; then
        success "Access to organization '${GFTAI_ORG_NAME}' confirmed for user '${gh_user}'."
        GH_AUTH_OK_FOR_ORG=true
    else
        error "Failed to confirm access to organization '${GFTAI_ORG_NAME}' for user '${gh_user}'."
        error "This could be due to insufficient token scopes or lack of membership/permissions within the organization."
        info "Please verify your GitHub token scopes and organization membership."
        GH_AUTH_OK_FOR_ORG=false
        return 1
    fi
    return 0
}

check_and_install_gh() { # MODIFIED: ensure gh_found_or_installed correctly influences ensure_gh_authenticated call
    step_info "A3: Checking/Installing GitHub CLI (gh) and Verifying Authentication..."
    local gh_found_or_installed=false
    if ! command_exists gh; then
        # ... (installation logic for gh - unchanged from v1.3.4) ...
        if $AUTO_INSTALL_TOOLS || confirm_action "GitHub CLI (gh) not found. Install it now?"; then
            info "Attempting to install GitHub CLI (gh)..."
            case "$OS_TYPE" in
                Linux) 
                    if type -p curl >/dev/null || (sudo apt update -qq && sudo apt install -y -qq curl); then
                        info "Attempting gh installation using official Linux script..."
                        if curl -fsSL https://cli.github.com/packages/install.sh | sudo bash; then gh_found_or_installed=true; else error "gh install script failed."; fi
                    else
                        error "curl is not available. Cannot download gh installation script."
                    fi ;;
                Darwin) 
                    if command_exists brew; then 
                        if brew install gh; then gh_found_or_installed=true; else error "brew install gh failed."; fi
                    else error "Brew not found, cannot install gh."; fi ;;
                *) error "Unsupported OS for automatic gh installation: $OS_TYPE" ;;
            esac
            if $gh_found_or_installed; then success "GitHub CLI (gh) installed successfully: $(gh --version 2>/dev/null | head -n1)"; else error "Failed to install GitHub CLI (gh)."; fi
        else
            warning "Skipping GitHub CLI (gh) installation."
        fi
    else
        success "GitHub CLI (gh) found: $(gh --version 2>/dev/null | head -n1)"
        gh_found_or_installed=true
    fi

    if $gh_found_or_installed; then
        ensure_gh_authenticated # Call the auth check/login function
    else
        GH_AUTH_OK_FOR_ORG=false 
    fi
    echo "-------------------------------------------------------------------"
} 


# MODIFIED: check_and_install_pyenv_python to install build dependencies for Python
install_pyenv_build_dependencies_ubuntu() {
    info "Attempting to install common Python build dependencies for Ubuntu/Debian via apt..."
    # Based on https://github.com/pyenv/pyenv/wiki/Common-build-problems
    local packages=(
        build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev curl \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    )
    # Using DEBIAN_FRONTEND=noninteractive to avoid prompts from apt
    if sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
       sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}"; then
        success "Common Python build dependencies installed/updated."
    else
        warning "Failed to install some Python build dependencies. 'pyenv install' might still fail for some Python versions."
    fi
}

check_and_install_pyenv_python() {
    step_info "A5: Checking/Installing Python (via pyenv is recommended) & Pre-commit..."
    local python_setup_ok=false
    local pip3_available=false

    if $AUTO_INSTALL_TOOLS || confirm_action "Python ${EXPECTED_PYTHON_VERSION_MAJOR}.${EXPECTED_PYTHON_VERSION_MINOR}+ (via pyenv is recommended) & pre-commit. Install/Verify?"; then
        export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}" 
        export PATH="$PYENV_ROOT/bin:$PATH"

        if ! command_exists pyenv; then
            info "pyenv (Python Version Manager) not found. Attempting to install pyenv..."
            # ... (pyenv installation logic - unchanged from v1.3.4) ...
            if curl https://pyenv.run | bash; then
                success "pyenv installation script downloaded and executed."
                if [[ -z "$PYENV_SHELL" ]]; then export PYENV_SHELL="$SHELL"; fi
                eval "$(pyenv init --path)" 
                eval "$(pyenv init -)"
                eval "$(pyenv virtualenv-init -)" 
                info "pyenv added to PATH and initialized for current session."
                info "For permanent effect, ensure the following are in your shell profile (e.g., ~/.bashrc, ~/.zshrc):"
                echo -e "  export PYENV_ROOT=\"\$HOME/.pyenv\"\n  command -v pyenv >/dev/null || export PATH=\"\$PYENV_ROOT/bin:\$PATH\"\n  eval \"\$(pyenv init -)\""
                PYENV_INSTALLED_NOW=true
            else
                error "Failed to download pyenv installation script."
            fi
        else
            success "pyenv found."
            if ! type pyenv | head -1 | grep -q 'function'; then 
                 eval "$(pyenv init --path)" 
                 eval "$(pyenv init -)"
                 eval "$(pyenv virtualenv-init -)" 
            fi
        fi

        if command_exists pyenv; then
            # Attempt to install build dependencies BEFORE pyenv install
            if [[ "$OS_TYPE" == "Linux" ]] && command_exists apt-get; then # Specifically for apt-based systems
                if confirm_action "Install/update common Python build dependencies now (requires sudo)? This helps pyenv build Python successfully."; then
                    install_pyenv_build_dependencies_ubuntu
                fi
            fi

            local target_py_install_version="${PYTHON_VERSION_FOR_PYENV:-3.11.9}" # Use specific full version
            
            info "Checking for Python version ${target_py_install_version} in pyenv..."
            if ! pyenv versions --bare | grep -Fxq "${target_py_install_version}"; then
                info "Python ${target_py_install_version} not found in pyenv. Attempting to install..."
                if pyenv install "${target_py_install_version}" -s; then 
                    success "Python ${target_py_install_version} installed successfully via pyenv."
                else
                    error "Failed to install Python ${target_py_install_version} via pyenv."
                    warning "This might be due to missing system build dependencies."
                    info "Consult: https://github.com/pyenv/pyenv/wiki/Common-build-problems"
                    info "If build dependencies were just installed, a new terminal session might be needed by pyenv."
                fi
            else
                info "Python ${target_py_install_version} is already installed via pyenv."
            fi
            
            # Set global or local version
            current_global=$(pyenv global 2>/dev/null || echo "system")
            if [[ "$current_global" != "$target_py_install_version" ]] && pyenv versions --bare | grep -Fxq "${target_py_install_version}"; then # Only if successfully installed
                if confirm_action "Set Python ${target_py_install_version} as pyenv global version?"; then
                    if pyenv global "${target_py_install_version}"; then
                        success "Python ${target_py_install_version} set as pyenv global."
                    else
                        error "Failed to set pyenv global Python version."
                    fi
                fi
            elif pyenv versions --bare | grep -Fxq "${target_py_install_version}"; then
                 info "Python $(pyenv global) is already the pyenv global version (or a version matching ${target_py_install_version})."
            fi
            pyenv rehash 
        elif [ "$PYENV_INSTALLED_NOW" != true ]; then
            warning "pyenv command not available. System Python will be checked."
        elif $PYENV_INSTALLED_NOW; then
            info "pyenv was just installed. A terminal restart or sourcing shell profile is likely needed."
        fi
        
        # General Python3 and Pip3 check (should now pick up pyenv version if global is set)
        if command_exists python3; then
            current_py_version=$(python3 --version 2>&1 | awk '{print $2}')
            success "python3 command found: Version ${current_py_version}"
            # Compare with expected major/minor from script top
            py_major_check=$(echo "$current_py_version" | cut -d. -f1)
            py_minor_check=$(echo "$current_py_version" | cut -d. -f2)
            if [[ "$py_major_check" -ge "$EXPECTED_PYTHON_VERSION_MAJOR" && "$py_minor_check" -ge "$EXPECTED_PYTHON_VERSION_MINOR" ]]; then
                 python_setup_ok=true
            else
                 warning "Python version ${current_py_version} is older than recommended ${EXPECTED_PYTHON_VERSION_MAJOR}.${EXPECTED_PYTHON_VERSION_MINOR}+."
                 python_setup_ok=false # Set to false if not meeting minimum for pre-commit
            fi
        else
            error "python3 command not found. Please install Python ${EXPECTED_PYTHON_VERSION_MAJOR}.${EXPECTED_PYTHON_VERSION_MINOR}+."
            python_setup_ok=false
        fi

        if command_exists pip3; then
            success "pip3 command found: $(pip3 --version 2>&1 | head -n1)"
            pip3_available=true
        else 
            warning "pip3 command not found. Attempting to ensure pip with Python 3..."
            if $python_setup_ok; then
                if (python3 -m ensurepip --user --upgrade || \
                   (curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py --user && rm get-pip.py)); then
                    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then export PATH="$HOME/.local/bin:$PATH"; fi
                    if command_exists pip3; then success "pip3 installed/ensured successfully."; pip3_available=true; 
                    else error "Still failed to make pip3 available."; fi
                else
                     error "Could not install/ensure pip3. Some Python package installations might fail."
                fi
            fi
        fi

        if $python_setup_ok && $pip3_available; then
            info "Checking for pre-commit..."
            if ! command_exists pre-commit; then
                if $AUTO_INSTALL_TOOLS || confirm_action "Pre-commit CLI not found. Install it now using pip3 (user local)?"; then
                    info "Installing pre-commit for the current user..."
                    if pip3 install --user --upgrade pre-commit; then
                        success "Pre-commit installed/updated successfully."
                        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                            export PATH="$HOME/.local/bin:$PATH" 
                            warning "\$HOME/.local/bin was not in your PATH. Added for this session."
                            info "Add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your shell profile for permanent effect."
                        fi
                        info "Run 'pre-commit --version' to verify: $(pre-commit --version 2>/dev/null | head -n1 || echo 'N/A')"
                    else
                        error "Failed to install pre-commit."
                    fi
                else
                    warning "Skipping pre-commit installation. Git pre-commit hooks will not run automatically."
                fi
            else
                success "Pre-commit found: $(pre-commit --version 2>/dev/null | head -n1 || echo 'version not parsable')"
            fi
        else
            warning "Python3 (${python_setup_ok}) or pip3 (${pip3_available}) not fully available/suitable, cannot install pre-commit automatically."
        fi
    else
        warning "Skipping Python/pyenv/pre-commit setup."
    fi
    echo "-------------------------------------------------------------------"
} 

# MODIFIED: setup_ssh_for_github to use the GH_AUTH_OK_FOR_ORG flag more directly
setup_ssh_for_github() {
    step_info "B1: Setting up SSH Key for GitHub..."
    # ensure_gh_authenticated should have been called by check_and_install_gh.
    # We rely on GH_AUTH_OK_FOR_ORG global flag here.

    local ssh_dir="$HOME/.ssh"
    local id_ed25519_file="${ssh_dir}/id_ed25519"
    local id_rsa_file="${ssh_dir}/id_rsa" 
    local ssh_key_file=""

    ensure_dir "$ssh_dir"
    chmod 700 "$ssh_dir" 

    if [ -f "$id_ed25519_file" ]; then
        info "Existing Ed25519 SSH key found: $id_ed25519_file"
        ssh_key_file="$id_ed25519_file"
    elif [ -f "$id_rsa_file" ]; then
        info "Existing RSA SSH key found: $id_rsa_file (Ed25519 is recommended for new keys)"
        ssh_key_file="$id_rsa_file"
    fi

    if [ -z "$ssh_key_file" ]; then
        if $AUTO_GENERATE_SSH_KEY || confirm_action "No existing SSH key found. Generate a new Ed25519 SSH key for GitHub now?"; then
            # ... (Key generation logic unchanged from v1.3.4) ...
            info "Generating a new Ed25519 SSH key..."
            local key_email="${GIT_USER_EMAIL:-}" 
            if [ -z "$key_email" ]; then
                _onboarding_print_status "Enter your email for the SSH key comment (associated with GitHub on ${GFTAI_ORG_NAME}): " "ACTION"
                read -r key_email_input
                if [ -z "$key_email_input" ]; then error "Email cannot be empty for SSH key generation."; echo "-------------------------------------------------------------------"; return 1; fi
                key_email="$key_email_input"
            fi
            if ssh-keygen -t ed25519 -C "$key_email" -f "$id_ed25519_file" -N ""; then 
                success "New Ed25519 SSH key generated successfully at ${id_ed25519_file}"
                ssh_key_file="$id_ed25519_file"
                chmod 600 "$id_ed25519_file" "$id_ed25519_file.pub"
            else
                error "Failed to generate SSH key."
                echo "-------------------------------------------------------------------"; return 1
            fi
        else
            warning "Skipping SSH key generation. You will need to set one up manually for SSH Git operations."
            echo "-------------------------------------------------------------------"; return 1
        fi
    fi

    if [ -n "$ssh_key_file" ] && [ -f "${ssh_key_file}.pub" ]; then
        info "Your public SSH key (${ssh_key_file}.pub) content:"
        cat "${ssh_key_file}.pub"
        echo 
        if $AUTO_ADD_SSH_KEY_TO_GITHUB; then
            if $GH_AUTH_OK_FOR_ORG && command_exists gh; then # Check the global flag
                if confirm_action "Add this public key to your GitHub account now using 'gh'?"; then
                    info "Attempting to add SSH public key to your GitHub account..."
                    local key_title="gftai-onboarding-$(hostname)-$(date +%Y%m%d)"
                    if gh ssh-key add "${ssh_key_file}.pub" --title "$key_title"; then
                        success "SSH public key added to your GitHub account with title '$key_title'."
                    else
                        error "Failed to add SSH key to GitHub via 'gh ssh-key add'."
                        info "This can happen if the key already exists on your account, or if 'gh' needs broader scopes for key management."
                        info "You can add it manually here: https://github.com/settings/ssh/new"
                    fi
                fi
            else # GH_AUTH_OK_FOR_ORG is false or gh not found
                 info "Cannot automatically add key to GitHub because 'gh' is not available or not authenticated for organization '${GFTAI_ORG_NAME}' (GH_AUTH_OK_FOR_ORG=${GH_AUTH_OK_FOR_ORG})."
                 info "Please add it manually: https://github.com/settings/ssh/new"
            fi
        else 
            info "To add this key to GitHub manually, copy the public key content above and paste it at: https://github.com/settings/ssh/new"
        fi
        
        info "Attempting to start ssh-agent (if not running) and add the SSH key..."
        if ! ssh-add -l &>/dev/null || ! ssh-add -l | grep -qF "$(ssh-keygen -lf "${ssh_key_file}" | awk '{print $2}')"; then
            if ssh-add "${ssh_key_file}"; then
                success "SSH key ${ssh_key_file} added to ssh-agent."
            else
                warning "Failed to add SSH key to ssh-agent. You may need to start ssh-agent manually (e.g., 'eval \$(ssh-agent -s)') and then run 'ssh-add ${ssh_key_file}'."
            fi
        else
            success "SSH key already added to an active ssh-agent."
        fi
    fi
    echo "-------------------------------------------------------------------"
} 

configure_git() {
    step_info "B2: Configuring Git Global Settings..."
    # ... (Logic from v1.3.1 is mostly fine, ensures prompting for user.name/email if not set) ...
    local git_config_changed_name=false
    local git_config_changed_email=false

    if [[ -z "$GIT_USER_NAME" ]]; then 
        if confirm_action "Git global user.name is not set or empty. Set it now?"; then
            _onboarding_print_status "Enter your full name for Git commits: " "ACTION"
            read -r git_name_input
            if [[ -n "$git_name_input" ]]; then
                if git config --global user.name "$git_name_input"; then 
                    GIT_USER_NAME="$git_name_input"; git_config_changed_name=true; 
                    success "Git global user.name set to: $GIT_USER_NAME"
                else 
                    error "Failed to set Git global user.name."
                fi
            else
                warning "Git user.name not provided, left unset globally."
            fi
        else
            warning "Skipping Git global user.name configuration."
        fi
    else
        info "Git global user.name already configured as: $GIT_USER_NAME"
    fi

    if [[ -z "$GIT_USER_EMAIL" ]]; then 
        if confirm_action "Git global user.email is not set or empty. Set it now?"; then
            _onboarding_print_status "Enter your email for Git commits (must match your GitHub verified email): " "ACTION"
            read -r git_email_input
            if [[ -n "$git_email_input" ]]; then
                if git config --global user.email "$git_email_input"; then
                    GIT_USER_EMAIL="$git_email_input"; git_config_changed_email=true;
                    success "Git global user.email set to: $GIT_USER_EMAIL"
                else
                    error "Failed to set Git global user.email."
                fi
            else
                warning "Git user.email not provided, left unset globally."
            fi
        else
            warning "Skipping Git global user.email configuration."
        fi
    else
        info "Git global user.email already configured as: $GIT_USER_EMAIL"
    fi

    if [[ -z "$GIT_USER_NAME" ]] || [[ -z "$GIT_USER_EMAIL" ]]; then
        warning "Git global user.name or user.email is not fully configured. Commits may not be properly attributed."
    fi

    info "Setting other Git global configurations..."
    if git config --global core.editor "code --wait"; then success "Git core.editor set to 'code --wait'."; else warning "Failed to set core.editor (VS Code 'code' command might not be in PATH or not installed)."; fi
    if git config --global pull.rebase false; then success "Git pull.rebase set to 'false' (merge strategy)."; else error "Failed to set pull.rebase."; fi
    if git config --global init.defaultBranch "${GIT_DEFAULT_BRANCH_NAME}"; then success "Git init.defaultBranch set to '${GIT_DEFAULT_BRANCH_NAME}'."; else error "Failed to set init.defaultBranch."; fi
    
    echo "-------------------------------------------------------------------"
} 

clone_studio_repos() {
    step_info "C: Cloning ALL ${#GFTAI_REPOS_TO_CLONE[@]} Configured GenCr@ft Studio Repositories..."
    echo "-----------------------------------------------------------------------------------"
    if ! $AUTO_CLONE_REPOS ; then 
        if ! confirm_action "Proceed with cloning ALL ${#GFTAI_REPOS_TO_CLONE[@]} repositories now?"; then
            info "Skipping repository cloning."
            echo "-----------------------------------------------------------------------------------"
            return
        fi
    fi

    # ensure_gh_authenticated should have set GH_AUTH_OK_FOR_ORG
    if ! $GH_AUTH_OK_FOR_ORG ; then 
        error "GitHub CLI 'gh' is not properly authenticated for organization '${GFTAI_ORG_NAME}'."
        error "Cannot clone repositories. Please ensure 'gh auth login' was successful in the previous step with necessary org access and scopes."
        echo "-----------------------------------------------------------------------------------"
        return
    fi
    
    local projects_base_path="${GFTAI_WORKSPACE_PARENT_DIR}" 
    ensure_dir "${projects_base_path}"
    
    info "Cloning repositories into '${projects_base_path}'. This may take a significant amount of time."
    local all_cloned_successfully=true
    local count_cloned=0
    local count_skipped=0
    local count_failed=0

    for repo_name_from_list in "${GFTAI_REPOS_TO_CLONE[@]}"; do
        # ... (logic for getting repo_name_only and target_dir unchanged from v1.3.4) ...
        local repo_name_only
        if [[ "$repo_name_from_list" == */* ]]; then
            repo_name_only="${repo_name_from_list#*/}"
        else
            repo_name_only="$repo_name_from_list"
        fi
        if [ -z "$repo_name_only" ]; then continue; fi
        local target_dir="${projects_base_path}/${repo_name_only}" 

        if [ -d "${target_dir}/.git" ]; then 
            info "Repository '${repo_name_only}' already exists at '${target_dir}'. Skipping clone."
            ((count_skipped++))
        else
            ensure_dir "$(dirname "${target_dir}")" 
            info "Cloning '${GFTAI_ORG_NAME}/${repo_name_only}' into '${target_dir}'..."
            if gh repo clone "${GFTAI_ORG_NAME}/${repo_name_only}" "${target_dir}" -- --depth 1 --single-branch --no-tags; then
                # ... (rest of the cloning success logic, including pre-commit hook install - unchanged from v1.3.4) ...
                success "Repository '${GFTAI_ORG_NAME}/${repo_name_only}' cloned (shallow) successfully."
                ((count_cloned++))
                if [[ -n "$GIT_USER_NAME" ]] && [[ -n "$GIT_USER_EMAIL" ]]; then
                    (cd "${target_dir}" && git config user.name "$GIT_USER_NAME" && git config user.email "$GIT_USER_EMAIL")
                fi
                if command_exists pre-commit && [ -f "${target_dir}/.pre-commit-config.yaml" ]; then
                    info "Found .pre-commit-config.yaml in ${repo_name_only}. Installing pre-commit hooks..."
                    if (cd "${target_dir}" && pre-commit install && pre-commit install --hook-type commit-msg && pre-commit install --hook-type pre-push); then 
                        success "Pre-commit hooks (commit-msg, pre-commit, pre-push) installed successfully for ${repo_name_only}."
                    else
                        warning "Failed to install some pre-commit hooks for ${repo_name_only}."
                    fi
                fi
            else
                error "Failed to clone repository '${GFTAI_ORG_NAME}/${repo_name_only}'. (Is it private/internal and 'gh' auth failed for org?)"
                all_cloned_successfully=false
                ((count_failed++))
            fi
        fi
    done

    info "Repository cloning phase summary: ${count_cloned} cloned, ${count_skipped} skipped (existed), ${count_failed} failed."
    if ! $all_cloned_successfully; then
        warning "Some repositories could not be cloned. Please check the logs above."
    else
        success "All specified repositories processed."
    fi
    echo "-----------------------------------------------------------------------------------"
}

create_vscode_workspace() {
    step_info "D: Creating VS Code Workspace for ALL Cloned Repositories..."
    echo "----------------------------------------------------------------"
    # ... (Logic from v1.3.1 - ensure all GFTAI_REPOS_TO_CLONE are added if cloned) ...
    if ! $AUTO_CREATE_WORKSPACE && ! confirm_action "Do you want to create/update the VS Code workspace file with ALL cloned repositories?"; then
        info "Skipping VS Code workspace file creation."
        echo "----------------------------------------------------------------"
        VSCODE_WORKSPACE_CREATED_OR_UPDATED=false
        return
    fi

    local projects_base_path="${GFTAI_WORKSPACE_PARENT_DIR}" 
    local workspace_file_path="${projects_base_path}/${GFTAI_VSCODE_WORKSPACE_FILENAME}" 
    
    local workspace_content="{\n\t\"folders\": ["
    local first_folder=true

    info "Scanning '${projects_base_path}' for cloned GenCr@ft repositories to add to workspace: ${workspace_file_path}"
    for repo_name_from_list in "${GFTAI_REPOS_TO_CLONE[@]}"; do # Use the full list
        local repo_name_only
        if [[ "$repo_name_from_list" == */* ]]; then
            repo_name_only="${repo_name_from_list#*/}"
        else
            repo_name_only="$repo_name_from_list"
        fi
        if [ -z "$repo_name_only" ]; then continue; fi

        local repo_actual_path="${projects_base_path}/${repo_name_only}"

        if [ -d "$repo_actual_path/.git" ]; then 
            if [ "$first_folder" = true ]; then
                first_folder=false
            else
                workspace_content+=","
            fi
            workspace_content+="\n\t\t{\n\t\t\t\"path\": \"${repo_name_only}\"\n\t\t}" # Path relative to workspace file
        else
            info "Repository folder '${repo_name_only}' not found or not a git repo in '${projects_base_path}'. Not adding to workspace."
        fi
    done
    
    workspace_content+="\n\t],\n\t\"settings\": {\n"
    workspace_content+="\t\t\"workbench.colorTheme\": \"Default Dark+\",\n"
    workspace_content+="\t\t\"workbench.iconTheme\": \"vscode-icons\",\n"
    workspace_content+="\t\t\"files.exclude\": {\n"
    workspace_content+="\t\t\t\"**/.git\": true,\n\t\t\t\"**/.DS_Store\": true,\n\t\t\t\"**/Thumbs.db\": true,\n"
    workspace_content+="\t\t\t\"**/.venv*/**\": true,\n\t\t\t\"**/.pyenv*/**\": true,\n\t\t\t\"**/node_modules/**\": true,\n"
    workspace_content+="\t\t\t\"**/.terraform/**\": true,\n\t\t\t\"**/.terragrunt-cache/**\": true,\n"
    workspace_content+="\t\t\t\"**/*.tfstate*\": true\n\t\t},\n"
    workspace_content+="\t\t\"terminal.integrated.defaultProfile.linux\": \"bash\",\n"
    workspace_content+="\t\t\"terminal.integrated.defaultProfile.osx\": \"zsh\",\n"
    workspace_content+="\t\t\"editor.formatOnSave\": true,\n"
    workspace_content+="\t\t\"[python]\": {\n\t\t\t\"editor.defaultFormatter\": \"ms-python.black-formatter\",\n\t\t\t\"editor.formatOnSave\": true\n\t\t},\n"
    workspace_content+="\t\t\"[markdown]\": {\n\t\t\t\"editor.defaultFormatter\": \"yzhang.markdown-all-in-one\",\n\t\t\t\"editor.formatOnSave\": true\n\t\t},\n"
    workspace_content+="\t\t\"[json]\": {\n\t\t\t\"editor.defaultFormatter\": \"esbenp.prettier-vscode\",\n\t\t\t\"editor.formatOnSave\": true\n\t\t},\n"
    workspace_content+="\t\t\"[yaml]\": {\n\t\t\t\"editor.defaultFormatter\": \"redhat.vscode-yaml\",\n\t\t\t\"editor.formatOnSave\": true\n\t\t}\n"
    workspace_content+="\t}\n}"


    if echo -e "$workspace_content" > "$workspace_file_path"; then
        success "VS Code workspace file created/updated: ${workspace_file_path}"
        VSCODE_WORKSPACE_CREATED_OR_UPDATED=true
    else
        error "Failed to create/update VS Code workspace file at ${workspace_file_path}."
        VSCODE_WORKSPACE_CREATED_OR_UPDATED=false
    fi
    echo "----------------------------------------------------------------"
}

install_vscode_extensions() {
    step_info "E: Installing Recommended VS Code Extensions..."
    echo "-----------------------------------------------------"
    if ! $AUTO_INSTALL_VSCODE_EXTENSIONS ; then
        if ! confirm_action "Install/Verify ${#VSCODE_EXTENSIONS_TO_INSTALL[@]} recommended VS Code extensions?"; then
            info "Skipping VS Code extension installation."
            echo "-----------------------------------------------------"
            return
        fi
    fi

    if command_exists code; then
        info "Installing/verifying ${#VSCODE_EXTENSIONS_TO_INSTALL[@]} VS Code extensions..."
        local all_ext_ok=true
        local installed_count=0
        local already_installed_count=0
        local failed_count=0

        for ext_id in "${VSCODE_EXTENSIONS_TO_INSTALL[@]}"; do
            if [ -n "$ext_id" ]; then 
                info "Processing extension: $ext_id"
                if code --list-extensions | grep -qi "^${ext_id}$"; then 
                    success " --> '$ext_id' already installed."
                    ((already_installed_count++))
                else
                    if code --install-extension "$ext_id" --force; then 
                        success " --> '$ext_id' installed successfully."
                        ((installed_count++))
                    else
                        error " --> Failed to install '$ext_id'."
                        all_ext_ok=false
                        ((failed_count++))
                    fi
                fi
            fi
        done
        
        info "VS Code extension phase summary: ${installed_count} newly installed, ${already_installed_count} already present, ${failed_count} failed."
        if ! $all_ext_ok; then
            warning "Some VS Code extensions had issues during installation. Please check logs."
        else
            success "All specified VS Code extensions processed."
        fi
        if [ "$installed_count" -gt 0 ]; then
             info "You may need to restart VS Code for newly installed extensions to take full effect."
        fi
    else
        warning "VS Code CLI 'code' not found. Skipping VS Code extension installation."
    fi
    echo "-----------------------------------------------------"
} 

final_steps_and_summary() {
    step_info "F: Final Steps & Summary"
    echo "-------------------------------------------------------------------"
    info "G@FT.ai Developer Environment Onboarding Script has processed all selected steps."
    
    local projects_base_path="${GFTAI_WORKSPACE_PARENT_DIR}"
    local workspace_file_path="${projects_base_path}/${GFTAI_VSCODE_WORKSPACE_FILENAME}"

    if $VSCODE_WORKSPACE_CREATED_OR_UPDATED; then
        info "VS Code workspace file is ready at: ${workspace_file_path}"
        if $AUTO_OPEN_VSCODE && $VSCODE_CLI_AVAILABLE; then
            if confirm_action "Do you want to open the G@FT.ai Studio workspace in VS Code now?"; then
                info "Opening G@FT.ai Studio workspace in VS Code: ${workspace_file_path}"
                if ! code "${workspace_file_path}"; then # Try opening workspace file directly
                    error "Failed to open VS Code workspace file automatically. Trying parent folder..."
                    if ! code "${projects_base_path}"; then # Fallback to opening parent folder
                        error "Failed to open VS Code automatically. Please open it manually by opening the folder '${projects_base_path}' and selecting the '${GFTAI_VSCODE_WORKSPACE_FILENAME}' file."
                    else
                        success "VS Code launched with the parent folder. Please select the workspace file if not opened by default."
                    fi
                else
                    success "VS Code launched with the workspace."
                fi
            else
                info "VS Code workspace not opened automatically. You can open it later at: ${workspace_file_path}"
            fi
        else
             info "Please open the G@FT.ai Studio workspace manually with VS Code: File > Open Workspace from File... > ${workspace_file_path}"
        fi
    elif [ "$VSCODE_CLI_AVAILABLE" = false ] && $AUTO_CREATE_WORKSPACE_DEFAULT; then 
        info "VS Code CLI 'code' was not found. If the workspace was intended to be created, please open the parent folder '${projects_base_path}' in VS Code and look for the .code-workspace file or create one."
    fi

    echo
    success "####################################################################"
    success "# G@FT.ai Developer Environment Onboarding Script has completed!   #"
    success "####################################################################"
    info "IMPORTANT NEXT STEPS & REMINDERS:"
    if $NVM_INSTALLED_NOW; then
        info "- NVM was just installed. CLOSE and REOPEN your terminal, or source your shell profile (e.g., 'source ~/.bashrc' or 'source ~/.zshrc'). Then, you might need to run 'nvm install --lts' if Node.js didn't install."
    fi
    if $PYENV_INSTALLED_NOW; then
        info "- Pyenv was just installed. CLOSE and REOPEN your terminal, or source your shell profile and follow pyenv's instructions to complete setup (e.g., 'pyenv install <version>' and 'pyenv global <version>')."
    fi
    if $AUTO_INSTALL_VSCODE_EXTENSIONS && (( installed_count > 0 || failed_count > 0 )); then # Access global counts
        info "- If any VS Code extensions were newly installed/updated or failed, you might need to RELOAD or RESTART VS Code and check manually."
    fi
    info "- Your G@FT.ai studio workspace, if created, is at: ${workspace_file_path}"
    info "- For repositories with a '.pre-commit-config.yaml', remember to run the following commands inside each repository's local clone to activate local git hooks:"
    info "    cd /path/to/cloned_repo"
    info "    pre-commit install"
    info "    pre-commit install --hook-type commit-msg"
    info "    pre-commit install --hook-type pre-push"
    info "- Review any WARNING or ERROR messages above for manual follow-up."
    echo
} 

# --- Main Function ---
main() {
    # ... (Définition des variables globales de statut comme dans v1.3.2) ...
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ENV_FILE_LOADED=false
    VSCODE_WORKSPACE_CREATED_OR_UPDATED=false 
    VSCODE_CLI_AVAILABLE=$(command_exists code && echo true || echo false)
    NVM_INSTALLED_NOW=false 
    PYENV_INSTALLED_NOW=false
    # declare -g GH_AUTH_OK_FOR_ORG=false # Moved to top level global vars
    declare -g installed_count=0 
    declare -g already_installed_count=0
    declare -g failed_count=0

    clear 
    echo -e "${COLOR_BLUE}======================================================================${COLOR_RESET}"
    echo -e "${COLOR_GREEN} G@FT.ai Studio - Developer Environment Onboarding Script v1.3.3 ${COLOR_RESET}" # Updated version
    echo -e "${COLOR_BLUE}======================================================================${COLOR_RESET}"
    # ... (reste du main comme dans v1.3.2, s'assurant que ensure_gh_authenticated est appelé AVANT setup_ssh_for_github si AUTO_ADD_SSH_KEY_TO_GITHUB est vrai, et AVANT clone_studio_repos)

    load_env_file 
    # ... (affichage de la configuration) ...

    OS_TYPE=$(uname -s) 
    info "Detected OS Type: $OS_TYPE"

    step_info "SECTION A: Prerequisite Tools Installation..."
    check_and_install_homebrew 
    check_and_install_git
    check_and_install_gh # This now includes ensure_gh_authenticated
    check_and_install_nvm_node 
    check_and_install_pyenv_python 
    check_and_install_docker

    step_info "SECTION B: Git & GitHub Setup..."
    # ensure_gh_authenticated called by check_and_install_gh, but if gh was already installed, might need to call it again
    # or ensure check_and_install_gh always calls it if gh is found.
    # For safety, call ensure_gh_authenticated if we plan to do operations requiring gh auth.
    if $AUTO_GENERATE_SSH_KEY || $AUTO_ADD_SSH_KEY_TO_GITHUB || $AUTO_CLONE_REPOS ; then
        if ! $GH_AUTH_OK_FOR_ORG ; then # If not already confirmed by check_and_install_gh
            ensure_gh_authenticated
        fi
    fi

    if $AUTO_GENERATE_SSH_KEY || $AUTO_ADD_SSH_KEY_TO_GITHUB || confirm_action "Setup SSH key for GitHub?"; then
        setup_ssh_for_github # This function will re-check GH_AUTH_OK_FOR_ORG for adding key
    else
        info "Skipping SSH Key setup."
    fi
    
    configure_git 

    if $AUTO_CLONE_REPOS; then 
        if ! $GH_AUTH_OK_FOR_ORG; then # Check again specifically before cloning
             warning "Cannot clone repositories as GitHub CLI is not properly authenticated for organization '${GFTAI_ORG_NAME}'."
        else
            clone_studio_repos
        fi
    else 
        # ... (prompt user for cloning)
        if confirm_action "Clone ALL ${#GFTAI_REPOS_TO_CLONE[@]} configured G@FT.ai Studio repositories now?"; then
            if ! $GH_AUTH_OK_FOR_ORG; then # Check again
                 warning "Cannot clone repositories as GitHub CLI is not properly authenticated for organization '${GFTAI_ORG_NAME}'."
            else
                 clone_studio_repos
            fi
        else
            info "Skipping repository cloning. You can clone them manually later."
        fi
    fi
    
    # ... (reste du main comme dans v1.3.2)
    if $AUTO_CREATE_WORKSPACE; then 
        create_vscode_workspace
    else
        if confirm_action "Create/Update VS Code workspace file now?"; then
            create_vscode_workspace
        else
            info "Skipping VS Code workspace file creation."
            VSCODE_WORKSPACE_CREATED_OR_UPDATED=false
        fi
    fi
    
    if $AUTO_INSTALL_VSCODE_EXTENSIONS; then 
        install_vscode_extensions
    else
        if confirm_action "Install/Verify recommended VS Code extensions now?"; then
            install_vscode_extensions
        else
            info "Skipping VS Code extension installation."
        fi
    fi

    final_steps_and_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize global flags
    GH_AUTH_OK_FOR_ORG=false 
    NVM_INSTALLED_NOW=false
    PYENV_INSTALLED_NOW=false
    VSCODE_WORKSPACE_CREATED_OR_UPDATED=false 
    VSCODE_CLI_AVAILABLE=false 
    declare -g installed_count=0 
    declare -g already_installed_count=0
    declare -g failed_count=0

    main "$@" 
fi
