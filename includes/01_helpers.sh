#!/usr/bin/env bash

# ==============================================================================
# Onboarding Script - Part 1: Helper Functions
#
# Contains utility functions for logging, color output, and user interaction.
# This file is meant to be sourced by the main script.
# ==============================================================================

# --- Global Variables for UI ---
readonly GFT_COLOR_BLUE="\033[1;34m"
readonly GFT_COLOR_GREEN="\033[1;32m"
readonly GFT_COLOR_RED="\033[1;31m"
readonly GFT_COLOR_YELLOW="\033[1;33m"
readonly GFT_COLOR_RESET="\033[0m"

# --- Logging Functions ---

# Prints an informational message.
# Usage: log_info "Doing a thing..."
log_info() {
    echo -e "${GFT_COLOR_BLUE}[INFO]${GFT_COLOR_RESET} $1"
}

# Prints a success message.
# Usage: log_success "Thing done."
log_success() {
    echo -e "${GFT_COLOR_GREEN}[SUCCESS]${GFT_COLOR_RESET} $1"
}

# Prints a warning message.
# Usage: log_warn "This might be an issue."
log_warn() {
    echo -e "${GFT_COLOR_YELLOW}[WARN]${GFT_COLOR_RESET} $1"
}

# Prints an error message.
# Usage: log_error "Something failed."
log_error() {
    echo -e "${GFT_COLOR_RED}[ERROR]${GFT_COLOR_RESET} $1" >&2
}

# --- User Interaction Functions ---

# Prompts the user for a yes/no confirmation.
# Returns 0 (success) for "yes", 1 (failure) for "no".
# Usage: if confirm_action "Do the thing?"; then ...; fi
confirm_action() {
    local prompt="$1"
    while true; do
        read -p -r "$prompt [y/N]: " response
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]*|"" ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

check_prerequisites() {
    log_info "Checking for required system tools (git, curl, yq)..."
    local missing_tool=0
    for tool in git curl yq; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool '$tool' is not installed. Please install it and re-run the script."
            missing_tool=1
        fi
    done
    if [ "$missing_tool" -eq 1 ]; then
        exit 1
    fi
    log_success "All prerequisite tools are present."
}

# --- SSoT Management ---

# Clones or pulls the gcs-devops-standards repository to a temporary path.
# This ensures the script always uses the latest SSoT configuration.
setup_ssot_repository() {
    log_info "Setting up SSoT configuration repository..."
    if [ -d "$GFT_SSOT_PATH" ]; then
        log_info "Updating existing SSoT repository at $GFT_SSOT_PATH..."
        (cd "$GFT_SSOT_PATH" && git pull --ff-only)
    else
        log_info "Cloning SSoT repository into $GFT_SSOT_PATH..."
        git clone --depth 1 "$GFT_SSOT_REPO" "$GFT_SSOT_PATH"
    fi
    log_success "SSoT repository is up to date."
}

# Loads the YAML content from the Role-Tooling matrix into a global variable.
load_ssot_configuration() {
    log_info "Loading role and tooling data from SSoT..."
    local matrix_file
    # Find the file, as its name might change slightly.
    matrix_file=$(find "$GFT_SSOT_PATH" -type f -name "*role-tooling--resource-matrix.md")

    if [[ -z "$matrix_file" ]]; then
        log_error "Could not find the role-tooling--resource-matrix.md file in $GFT_SSOT_PATH"
        exit 1
    fi

    # Extract the YAML block from the Markdown file. Requires yq.
    # The sed commands remove the ```yaml markers.
    ROLE_MATRIX_YAML=$(sed -n '/```yaml/,/```/p' "$matrix_file" | sed '1d;$d')
    export ROLE_MATRIX_YAML

    log_success "SSoT configuration loaded."
}

# --- Role Selection ---

# Interactively prompts the user to select their role from the SSoT matrix.
# Returns the selected role name (e.g., "devops-specialist").
select_user_role() {
    if ! command -v yq &> /dev/null; then
        log_error "'yq' is not installed, but it is required to parse SSoT files."
        log_info "Please install 'yq' (e.g., 'sudo apt install yq' or 'brew install yq') and re-run the script."
        exit 1
    fi

    log_info "Please select your primary role in the studio:"
    # Use yq to parse roles from the global variable and format them for the `select` prompt.
    mapfile -t role_options < <(echo "$ROLE_MATRIX_YAML" | yq -r '.roles[] | select(.name != "common-base") | .name + ": " + .description')

    local selected_role_name
    select role_choice in "${role_options[@]}"; do
        if [[ -n "$role_choice" ]]; then
            selected_role_name=$(echo "$role_choice" | cut -d':' -f1)
            log_info "You have selected the role: $selected_role_name"
            echo "$selected_role_name" # Return the value
            return 0
        else
            log_warn "Invalid selection. Please try again."
        fi
    done
}
