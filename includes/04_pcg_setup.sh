#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_PCG_SETUP_04
# Title: Onboarding Script - PCG Research Environment Setup
# Author(s): AI Gemini CLI
# Creation Date: 2026-05-02
# Version: 1.0.0
#
# Description:
#   This script automates the setup of the Python research environment for the
#   PCG module (gcp-aethel-pcg). It creates a dedicated virtual environment
#   and installs the required libraries (noise, pytest).

setup_pcg_python_venv() {
    local role_name="$1"
    
    # This setup is specifically for PCG specialists or rendering developers
    if [[ "$role_name" != "pcg-specialist" && "$role_name" != "rendering-engine-developer" && "$role_name" != "architecture-lead" ]]; then
        return 0
    fi

    log_info "Setting up PCG Python research environment..."

    local gft_workspace="${GFT_PROJECTS_HOME:-$HOME/gft_studio}"
    local pcg_dir="${gft_workspace}/gcp-aethel-pcg/pcg-godot"

    if [ ! -d "$pcg_dir" ]; then
        log_warn "PCG directory not found at $pcg_dir. Skipping Python venv setup."
        return 0
    fi

    if ! python3 -m venv --help > /dev/null 2>&1; then
        log_error "python3-venv is not installed. Please run: sudo apt update && sudo apt install -y python3.12-venv"
        return 1
    fi

    (
        cd "$pcg_dir" || exit 1
        if [ -d ".pcg" ]; then
            log_info "PCG virtual environment already exists. Updating dependencies..."
        else
            log_info "Creating PCG virtual environment in $pcg_dir/.pcg..."
            python3 -m venv .pcg
        fi
        
        log_info "Installing PCG research dependencies (noise, pytest)..."
        ./.pcg/bin/pip install --upgrade pip > /dev/null
        if ./.pcg/bin/pip install noise pytest > /dev/null; then
            log_success "PCG Python environment configured successfully."
        else
            log_error "Failed to install PCG dependencies."
            exit 1
        fi
    ) || return 1
}
