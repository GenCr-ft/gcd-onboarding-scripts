#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_MAIN_ORCHESTRATOR
# Title: GenCr@t Studio - Onboarding Script V2 (Main Orchestrator)
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-09
# Last Modified Date: 2025-06-26
# Version: 2.2.0
#
# Description:
#   This script is the main entry point for the GenCr@t developer onboarding process.
#   It orchestrates the validation of prerequisites, setup of the SSoT repository,
#   and calls the various installation and configuration modules.
#
# Usage:
#   ./gft-onboarding.sh
#
# Dependencies:
#   - Sources includes/01_helpers.sh, 02_installers.sh, 03_configuration.sh
#   - External commands: git, curl, yq, python3
# --- Script Configuration and Robustness ---
set -e
set -u
set -o pipefail

# Find the script's own directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
INCLUDES_DIR="${SCRIPT_DIR}/includes"

# --- Source All Helper and Logic Files ---
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/01_helpers.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/02_installers.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/03_configuration.sh"

# --- SSoT Configuration ---
readonly GFT_SSOT_REPO="https://github.com/GenCr-ft/gcs-devops-standards.git"
readonly GFT_SSOT_PATH="/tmp/gft-ssot-onboarding"

# --- Main Orchestration ---
main() {
    log_info "Welcome to the GenCr@t Studio Onboarding Script V2!"

    # --- Prerequisite & SSoT Setup ---
    check_prerequisites
    setup_ssot_repository
    detect_os

    # --- Load Configuration from SSoT ---
    load_ssot_configuration

    # --- Role Selection ---
    local selected_role_name
    selected_role_name=$(select_user_role)

    # --- Execution Flow ---
    install_tools_for_role "$selected_role_name"

    # --- Configuration Flow ---
    configure_git
    setup_ssh_key
    install_vscode_extensions_for_role "$selected_role_name"
    clone_repositories_for_role "$selected_role_name"

    # --- Final Tooling Configuration ---
    configure_gft_cli

    # Final summary
    log_success "############################################################"
    log_success "# Onboarding Complete! Welcome to GenCr@t Studio.           #"
    log_success "############################################################"
    log_info "Please restart your terminal session for all changes to take effect."
}

# --- Script Execution ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
