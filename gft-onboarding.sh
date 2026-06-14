#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_MAIN_ORCHESTRATOR
# Title: GenCr@ft Studio - Onboarding Script V2 (Main Orchestrator)
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-09
# Last Modified Date: 2026-05-11
# Version: 2.3.0
#
# Description:
#   This script is the main entry point for the GenCr@ft developer onboarding process.
#   It orchestrates the validation of prerequisites, setup of the SSoT repository,
#   and calls the various installation and configuration modules.
#
# Usage:
#   ./gft-onboarding.sh
#
# Dependencies:
#   - Sources includes/01_helpers.sh, 02_installers.sh, 03_configuration.sh, 04_pcg_setup.sh
#   - External commands: git, curl, yq, python3
# --- Script Configuration and Robustness ---
set -e
set -u
set -o pipefail

LOG_FILE="${HOME}/gft_onboarding_$(date +%F_%H-%M-%S).log"

# Find the script's own directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
INCLUDES_DIR="${SCRIPT_DIR}/includes"

# --- Source All Helper and Logic Files ---
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/00_bootstrap.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/01_helpers.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/02_installers.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/03_configuration.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/04_pcg_setup.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/05_agent_bootstrap.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/06_workspace_files.sh"
# shellcheck disable=SC1091
source "${INCLUDES_DIR}/07_preflight.sh"

# --- Logging Setup ---
setup_log_stream() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    log_info "Streaming logs to $LOG_FILE"
}

# --- SSoT Configuration ---
# shellcheck disable=SC2034
readonly GFT_SSOT_REPO="https://github.com/GenCr-ft/gcs-core-governance.git"
# shellcheck disable=SC2034
readonly GFT_SSOT_PATH="/tmp/gft-ssot-onboarding"


# --- Hook Registration ---
register_studio_hooks() {
    log_info "Registering studio-standard lifecycle hooks in ~/.claude/settings.local.json..."

    local gemop_path="${GFT_SSOT_GEMOP_PATH:-}"
    if [[ -z "$gemop_path" ]]; then
        local workspace="${GFT_PROJECTS_HOME:-${HOME}/gft_studio}"
        gemop_path="${workspace}/gcs-plt-gemop"
    fi

    local hooks_dir="${gemop_path}/hooks"
    if [[ ! -d "$hooks_dir" ]]; then
        log_warn "Hooks directory not found at ${hooks_dir}. Skipping hook registration."
        return 0
    fi

    local git_safety_hook="${hooks_dir}/git-safety-check.sh"
    local persona_linter_hook="${hooks_dir}/persona-linter.sh"
    local date_updater_hook="${hooks_dir}/date-updater.py"

    # Make hooks executable
    for h in "$git_safety_hook" "$persona_linter_hook" "$date_updater_hook"; do
        [[ -f "$h" ]] && chmod +x "$h"
    done

    local settings_file="${HOME}/.claude/settings.local.json"
    mkdir -p "${HOME}/.claude"

    # Merge hook registrations into settings.local.json, preserving other keys
    python3 - "$settings_file" "$git_safety_hook" "$persona_linter_hook" "$date_updater_hook" <<'PYEOF'
import json, sys
from pathlib import Path

settings_path = Path(sys.argv[1])
git_safety = sys.argv[2]
persona_linter = sys.argv[3]
date_updater = sys.argv[4]

existing = {}
if settings_path.exists():
    try:
        existing = json.loads(settings_path.read_text())
    except Exception:
        existing = {}

existing["hooks"] = {
    "PreToolUse": [
        {
            "matcher": "Bash",
            "hooks": [{"type": "command", "command": git_safety}]
        }
    ],
    "PostToolUse": [
        {
            "matcher": "Edit|Write|MultiEdit",
            "hooks": [
                {"type": "command", "command": persona_linter},
                {"type": "command", "command": f"python3 {date_updater}"}
            ]
        }
    ]
}

settings_path.write_text(json.dumps(existing, indent=2) + "\n")
print(f"Hooks registered in {settings_path}")
PYEOF

    log_success "Studio hooks registered in ${settings_file}."
}

# --- Main Orchestration ---
main() {
    log_info "Welcome to the GenCr@ft Studio Onboarding Script V2!"

    # --- Prerequisite & SSoT Setup ---
    run_preflight
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
    configure_environment_variables "$selected_role_name"
    install_vscode_extensions_for_role "$selected_role_name"
    clone_repositories_for_role "$selected_role_name"
    install_gft_ops_scripts
    deploy_workspace_files
    deploy_planning_metadata_hook
    configure_agent_environment "$selected_role_name"
    register_studio_hooks
    setup_pcg_python_venv "$selected_role_name"

    # --- Final Tooling Configuration ---
    configure_gft_cli
    performance_and_caching
    final_validation

    # Final summary
    log_success "############################################################"
    log_success "# Onboarding Complete! Welcome to GenCr@ft Studio.          #"
    log_success "############################################################"
    log_info "Please restart your terminal session for all changes to take effect."
}

# --- Script Execution ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_log_stream

    if ! parse_cli_args "$@"; then
        exit 2
    fi

    if [[ "${GFT_SHOW_HELP_ONLY:-}" == "true" ]]; then
        exit 0
    fi

    if [[ "${GFT_SYNC_HOOKS_ONLY:-}" == "true" ]]; then
        deploy_planning_metadata_hook
        exit $?
    fi

    trap 'log_error "Onboarding aborted unexpectedly. Review $LOG_FILE and share it with DevOps."; exit 1' ERR

    main
fi
