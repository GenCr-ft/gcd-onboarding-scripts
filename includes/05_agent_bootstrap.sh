#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_AGENT_BOOTSTRAP_05
# Title: Onboarding Script - Agent Skills and Workspace Configuration
# Author(s): Gemini CLI
# Creation Date: 2026-05-02
# Version: 1.0.0
#
# Description:
#   This module ensures that the developer's environment is equipped with
#   the necessary agent skills and a project-level AGENT.md for both AI
#   and human contributors.

setup_agent_skills() {
    log_info "Deploying required agent skills..."
    local skills_dir="${HOME}/.agents/skills"
    local source_skills_dir="${SCRIPT_DIR}/skills"
    
    mkdir -p "$skills_dir"

    if [[ ! -d "$source_skills_dir" ]]; then
        log_warn "Skills source directory not found at $source_skills_dir. Skipping skill deployment."
        return 0
    fi

    # Deploy all .skill bundles from the repository
    local deployed=0
    for skill_bundle in "${source_skills_dir}"/*.skill; do
        if [[ -f "$skill_bundle" ]]; then
            local skill_name
            skill_name=$(basename "$skill_bundle" .skill)
            log_info "  Installing skill: $skill_name"
            
            # Create target dir and unzip (overwrite if exists)
            mkdir -p "${skills_dir}/${skill_name}"
            unzip -q -o "$skill_bundle" -d "${skills_dir}/${skill_name}"
            deployed=$((deployed + 1))
        fi
    done

    log_success "Deployed $deployed agent skills to $skills_dir."
}

generate_workspace_agent_md() {
    local role_name="${1:-generic-contributor}"
    log_info "Generating role-specific AGENT.md for: $role_name"
    
    local target_dir="${GFT_PROJECTS_HOME:-$(pwd)}"
    local target_file="${target_dir}/AGENT.md"

    # Role-specific content
    local role_instructions=""
    case "$role_name" in
        "game-developer")
            role_instructions="- **Stack:** Godot 4.5, GDScript, Rust (WASM).
- **Primary Tests:** \`wt-gut\` (Client), \`cargo test\` (Server).
- **MO:** Focus on PCG parity and Voxel performance."
            ;;
        "devops-specialist")
            role_instructions="- **Stack:** Python, Tofu (IaC), Bash.
- **Primary Tests:** \`wt-pytest\` (Ops), \`pre-commit\` (SSoT).
- **MO:** Focus on automation and infrastructure robustness."
            ;;
        *)
            role_instructions="- **Orientation:** Refer to \`CLAUDE.md\` for general workspace patterns.
- **Tests:** Run root \`./test-all.sh\` to verify your changes."
            ;;
    esac

    cat << EOF > "$target_file"
# AGENT.md — GenCr@ft Studio Workspace ($role_name)

## Orientation
You are an agent (AI or Human) in the **$role_name** role.
This workspace contains ~30 repositories for the **Aethel** project.

## Role Specifics
$role_instructions

## Quick Start
1. **Validate:** Run \`gft aethel validate\` to check binaries and repo clones.
2. **Read:** \`CLAUDE.md\` at root for patterns and workflows.
3. **Status:** Check \`REMEDIATION.md\` for roadmap status.

## Productivity Cheat Sheet
- **Common Tests:** \`./test-all.sh --no-integration\`
- **PR Creation:** \`gh pr create --fill\`
- **Context:** Check \`~/.claude/projects/.../memory/MEMORY.md\`.

## Mandatory Skills
Ensure these skills are activated for your tasks:
- \`planning-with-files\` (Mandatory for multi-step tasks)
- \`architecture-decision-records\` (Before major design changes)
- \`code-review-excellence\` (When reviewing PRs)

## Core Workflow Mandates
- **TDD Always:** Never write production code without a failing test.
- **One PR per WI:** Keep changes atomic and linked to a GitHub Issue.
- **English Only:** All code and docs must be in English.
- **SSoT Driven:** Respect docIds and YAML frontmatter.
EOF

    log_success "AGENT.md generated for role '$role_name'."
}

configure_agent_environment() {
    local role_name="${1:-generic-contributor}"
    setup_agent_skills
    generate_workspace_agent_md "$role_name"
}
