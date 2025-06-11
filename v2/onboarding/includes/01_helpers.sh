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
