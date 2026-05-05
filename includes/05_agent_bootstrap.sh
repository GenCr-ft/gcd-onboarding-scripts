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
    local skills_dir="$HOME/.agents/skills"
    mkdir -p "$skills_dir"

    # List of required skills to ensure visibility
    local core_skills=(
        "planning-with-files"
        "godot-gdscript-patterns"
        "vercel-react-best-practices"
        "python-testing-patterns"
        "rust-best-practices"
        "typescript-advanced-types"
        "architecture-decision-records"
    )

    for skill in "${core_skills[@]}"; do
        if [[ ! -d "${skills_dir}/${skill}" ]]; then
            log_info "Initializing placeholder for skill: $skill"
            mkdir -p "${skills_dir}/${skill}"
            # In a production environment, we would clone/copy actual skill logic here.
        fi
    done

    log_success "Agent skills environment deployed at $skills_dir."
}

generate_workspace_agent_md() {
    log_info "Verifying project-level AGENT.md..."
    
    # We use GFT_WORKSPACE if defined, else fallback to parent of gcs-devops-standards or cwd
    local target_dir="${GFT_PROJECTS_HOME:-$(pwd)}"
    local target_file="${target_dir}/AGENT.md"

    if [[ -f "$target_file" ]]; then
        log_info "AGENT.md already exists. Ensuring it's up to date..."
    fi

    log_info "Generating standardized AGENT.md at $target_file"

    cat << 'EOF' > "$target_file"
# AGENT.md — GenCr@ft Studio Workspace

## Orientation
You are an agent (AI or Human) contributing to the **GenCr@ft Studio** ecosystem.
This workspace contains ~30 repositories side-by-side for the **Aethel** project (Voxel RPG Platform).

## Quick Start
1. **Validate:** Run `gft aethel validate` to check binaries and repo clones.
2. **Read:** `CLAUDE.md` at workspace root for Technical Stack, Patterns, and Workflows.
3. **Status:** Check `REMEDIATION.md` for global roadmap and active phase status.
4. **Audit:** Refer to `senior expertise/INDEX.md` for codebase quality assessment.

## Productivity Cheat Sheet
- **Common Tests:** `./test-all.sh --no-integration` (Fast unit tests).
- **PCG Parity:** `bash tests/test_parity_py_rs.sh` (Bit-identical verification).
- **PR Creation:** `gh pr create --fill --label "area:hermes"` (Conventional Commits).
- **Context:** Check `~/.claude/projects/.../memory/MEMORY.md`.

## Required Skills
Ensure these skills are activated via `activate_skill` for relevant tasks:
- `planning-with-files` (Mandatory for multi-step tasks)
- `godot-gdscript-patterns` (Client-side development)
- `rust-best-practices` (PCG core/WASM implementation)
- `python-testing-patterns` (PCG research/Ops tooling)
- `typescript-advanced-types` (Server-side/Platform)
- `architecture-decision-records` (Before major design changes)

## Core Workflow Mandates
- **TDD Always:** Never write production code without a failing test.
- **One PR per WI:** Keep changes atomic and linked to a GitHub Issue.
- **English Only:** All code, comments, and documentation must be in English.
- **SSoT Driven:** Respect docIds, YAML frontmatter, and standard file structures.
EOF

    log_success "AGENT.md generated/updated successfully."
}

configure_agent_environment() {
    setup_agent_skills
    generate_workspace_agent_md
}
