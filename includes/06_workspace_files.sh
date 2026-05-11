#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_WORKSPACE_FILES_06
# Title: Onboarding Script - Workspace-Level File Deployment
# Author(s): AI Enablement Lead
# Creation Date: 2026-05-11
# Version: 1.0.0
#
# Description:
#   Deploys versioned workspace-level scripts and docs from the workspace/
#   bundle in this repo to $GFT_PROJECTS_HOME (default: ~/gft_studio).
#   Idempotent: skips files that are already up to date; updates changed ones.

deploy_workspace_files() {
    local target="${GFT_PROJECTS_HOME:-${HOME}/gft_studio}"
    local source_dir="${SCRIPT_DIR}/workspace"

    log_info "Deploying workspace-level files to ${target}..."

    if [[ ! -d "$source_dir" ]]; then
        log_error "Workspace bundle not found at ${source_dir}."
        return 1
    fi

    mkdir -p "$target"

    local deployed=0 updated=0 skipped=0

    while IFS= read -r -d '' src_file; do
        local filename
        filename="$(basename "$src_file")"
        local dest_file="${target}/${filename}"

        if [[ -f "$dest_file" ]] && diff -q "$src_file" "$dest_file" >/dev/null 2>&1; then
            log_info "  ${filename} — up to date."
            skipped=$((skipped + 1))
            continue
        fi

        if [[ -f "$dest_file" ]]; then
            log_info "  ${filename} — updating."
            updated=$((updated + 1))
        else
            log_info "  ${filename} — installing."
            deployed=$((deployed + 1))
        fi

        cp "$src_file" "$dest_file"
        if [[ "$src_file" == *.sh ]]; then
            chmod +x "$dest_file"
        fi
    done < <(find "$source_dir" -maxdepth 1 -type f -print0 | sort -z)

    log_success "Workspace files: ${deployed} installed, ${updated} updated, ${skipped} up to date."
}
