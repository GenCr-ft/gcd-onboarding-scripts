#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_AGENT_BOOTSTRAP_05
# Title: Onboarding Script - Agent Skills and Workspace Configuration
# Author(s): Gemini CLI
# Creation Date: 2026-05-02
# Last Modified Date: 2026-05-23
# Version: 2.0.0
#
# Description:
#   This module ensures that the developer's environment is equipped with
#   the necessary agent skills, agent files, and a project-level AGENT.md
#   for both AI and human contributors.
#
# Change Log v2.0.0:
#   - setup_agent_skills(): replaced zip-unpack pattern with symlinks to
#     ~/.claude/skills/ from gcs-plt-gemop/skills/ (GCS-STD-002 v1.4.0)
#   - provision_agent_files(): new function — symlinks gemop agents/*.md
#     to ~/.claude/agents/ for Claude Code subagent discovery
#   - configure_agent_environment(): now calls provision_agent_files()
#   - generate_workspace_agent_md(): updated Mandatory Skills to the
#     current 6 standard skills (GCS-STD-003)

setup_agent_skills() {
    log_info "Deploying agent skills via symlinks..."
    local target_skills_dir="${HOME}/.claude/skills"
    local gemop_path="${GFT_SSOT_GEMOP_PATH:-}"

    # Auto-detect gemop path if not set
    if [[ -z "$gemop_path" ]]; then
        local workspace="${GFT_PROJECTS_HOME:-${HOME}/gft_studio}"
        gemop_path="${workspace}/gcs-plt-gemop"
    fi

    local source_skills_dir="${gemop_path}/skills"

    if [[ ! -d "$source_skills_dir" ]]; then
        log_warn "Skills source directory not found at ${source_skills_dir}. Skipping skill deployment."
        log_warn "Set GFT_SSOT_GEMOP_PATH to the path of the gcs-plt-gemop repository."
        return 0
    fi

    mkdir -p "$target_skills_dir"

    local linked=0 updated=0 skipped=0
    for skill_dir in "${source_skills_dir}"/*/; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name
            skill_name=$(basename "$skill_dir")
            local target_link="${target_skills_dir}/${skill_name}"

            if [[ -L "$target_link" ]] && [[ "$(readlink "$target_link")" == "$skill_dir" ]]; then
                skipped=$((skipped + 1))
                continue
            elif [[ -L "$target_link" ]]; then
                log_info "  Updating symlink: ${skill_name}"
                rm "$target_link"
                updated=$((updated + 1))
            else
                log_info "  Linking skill: ${skill_name}"
                linked=$((linked + 1))
            fi
            ln -s "$skill_dir" "$target_link"
        fi
    done

    log_success "Skills: ${linked} linked, ${updated} updated, ${skipped} already current."
}

provision_agent_files() {
    log_info "Provisioning agent files to ~/.claude/agents/..."
    local target_agents_dir="${HOME}/.claude/agents"
    local gemop_path="${GFT_SSOT_GEMOP_PATH:-}"

    if [[ -z "$gemop_path" ]]; then
        local workspace="${GFT_PROJECTS_HOME:-${HOME}/gft_studio}"
        gemop_path="${workspace}/gcs-plt-gemop"
    fi

    local source_agents_dir="${gemop_path}/agents"

    if [[ ! -d "$source_agents_dir" ]]; then
        log_warn "Agents source directory not found at ${source_agents_dir}. Skipping agent provisioning."
        return 0
    fi

    mkdir -p "$target_agents_dir"

    local linked=0 updated=0 skipped=0
    while IFS= read -r -d '' agent_file; do
        local agent_name
        agent_name=$(basename "$agent_file")
        # Skip grader.md — internal tool, not a deployable agent
        if [[ "$agent_name" == "grader.md" ]]; then
            continue
        fi
        local target_link="${target_agents_dir}/${agent_name}"

        if [[ -L "$target_link" ]] && [[ "$(readlink "$target_link")" == "$agent_file" ]]; then
            skipped=$((skipped + 1))
        elif [[ -L "$target_link" ]]; then
            rm "$target_link"
            ln -s "$agent_file" "$target_link"
            updated=$((updated + 1))
            log_info "  Updating agent: ${agent_name}"
        else
            ln -s "$agent_file" "$target_link"
            linked=$((linked + 1))
            log_info "  Linking agent: ${agent_name}"
        fi
    done < <(find "$source_agents_dir" -maxdepth 1 -name "*.md" -print0 | sort -z)

    log_success "Agents: ${linked} linked, ${updated} updated, ${skipped} already current."
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
Ensure these skills are available for your tasks. They are deployed to \`~/.claude/skills/\` by the onboarding script:
- \`gencraft-git-workflow\` — Branch creation, conventional commits, and PR workflow
- \`pr-lifecycle\` — Driving PRs through review and merge
- \`dev-work-item-authoring\` — Filing GitHub Issues for gaps and action items
- \`ssot-document-authoring\` — Authoring SSoT documents with correct frontmatter
- \`questioning-user\` — Structured clarification with the Studio Director
- \`questioning-inter-gem\` — Routing questions and escalations between agents

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
    provision_agent_files
    generate_workspace_agent_md "$role_name"
}
