#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_HELPERS_01
# Title: Onboarding Script - Helper Functions
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-09
# Last Modified Date: 2025-06-26
# Version: 2.2.0
#
# Description:
#   This script contains utility functions for logging, user interaction, SSoT
#   repository management, and prerequisite checks. It is a core library for
#   the onboarding process and is not meant to be executed directly.
#
# Usage:
#   This file is sourced by gft-onboarding.sh.
#
# Dependencies:
#   External commands: git, curl, yq, python3, sed, awk, find.


# --- Global Variables for UI ---
readonly GFT_COLOR_BLUE="\033[1;34m"
readonly GFT_COLOR_GREEN="\033[1;32m"
readonly GFT_COLOR_RED="\033[1;31m"
readonly GFT_COLOR_YELLOW="\033[1;33m"
readonly GFT_COLOR_RESET="\033[0m"

current_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# --- Logging Functions ---

# Prints an informational message.
# Usage: log_info "Doing a thing..."
log_info() {
    local message="$*"
    echo -e "${GFT_COLOR_BLUE}[INFO $(current_timestamp)]${GFT_COLOR_RESET} ${message}"
}

# Prints a success message.
# Usage: log_success "Thing done."
log_success() {
    local message="$*"
    echo -e "${GFT_COLOR_GREEN}[SUCCESS $(current_timestamp)]${GFT_COLOR_RESET} ${message}"
}

# Prints a warning message.
# Usage: log_warn "This might be an issue."
log_warn() {
    local message="$*"
    echo -e "${GFT_COLOR_YELLOW}[WARN $(current_timestamp)]${GFT_COLOR_RESET} ${message}"
}

# Prints an error message.
# Usage: log_error "Something failed."
log_error() {
    local message="$*"
    echo -e "${GFT_COLOR_RED}[ERROR $(current_timestamp)]${GFT_COLOR_RESET} ${message}" >&2
}

# --- User Interaction Functions ---

# Prompts the user for a yes/no confirmation.
# Returns 0 (success) for "yes", 1 (failure) for "no".
# Usage: if confirm_action "Do the thing?"; then ...; fi
confirm_action() {
    local prompt="$1"
    if [[ "${GFT_NON_INTERACTIVE:-}" == "true" ]]; then
        log_info "Non-interactive auto-confirm: $prompt -> yes"
        return 0
    fi
    while true; do
        read -r -p "$prompt [y/N]: " response
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]*|"" ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# --- CLI / Quickstart Helpers ---

# Four canonical workspaces (ENG-ADR-087). Legacy ids remain accepted as aliases
# and are canonicalized transparently for backward compatibility.
valid_workspaces() {
    printf '%s\n' \
        "aethel" \
        "gft-platform" \
        "onboarding" \
        "agent-ecosystem"
}

format_valid_workspaces() {
    printf '%s' "aethel, gft-platform, onboarding, agent-ecosystem"
}

# canonicalize_workspace <id> — echo the canonical id for a canonical or legacy id.
# Returns 1 (and echoes nothing) for an unknown id.
canonicalize_workspace() {
    case "$1" in
        aethel)                          printf '%s\n' "aethel" ;;
        gft-platform|evai-platform|studio-gencraft) printf '%s\n' "gft-platform" ;;
        onboarding|workspace-ops)        printf '%s\n' "onboarding" ;;
        agent-ecosystem|agent-factory)   printf '%s\n' "agent-ecosystem" ;;
        *) return 1 ;;
    esac
}

is_valid_workspace() {
    canonicalize_workspace "$1" >/dev/null 2>&1
}

workspace_role() {
    local workspace; workspace="$(canonicalize_workspace "$1")" || return 1
    case "$workspace" in
        aethel)          printf '%s\n' "rendering-engine-developer" ;;
        gft-platform)    printf '%s\n' "lead-developer-tech-lead" ;;
        onboarding)      printf '%s\n' "devops-specialist" ;;
        agent-ecosystem) printf '%s\n' "game-designer" ;;
        *) return 1 ;;
    esac
}

workspace_repositories() {
    local workspace; workspace="$(canonicalize_workspace "$1")" || return 1
    case "$workspace" in
        aethel)
            printf '%s\n' \
                "gcp-aethel-server" \
                "gcp-aethel-client" \
                "gcp-aethel-pcg" \
                "gcl-srv-authentication" \
                "gcl-srv-persistence" \
                "gcp-aethel-backlog"
            ;;
        gft-platform)
            printf '%s\n' \
                "gcs-plt-tools" \
                "gcs-plt-docs-req" \
                "gcs-plt-architecture" \
                "gcs-core-governance" \
                "gcs-engineering-handbook" \
                "gcs-security-core" \
                "gcs-studio-legal" \
                "gcs-project-management" \
                "gencr-ft.github.io"
            ;;
        onboarding)
            printf '%s\n' \
                "gcd-onboarding-scripts" \
                "gcd-ops-scripts" \
                "gcd-shared-actions" \
                "gencraft-iac"
            ;;
        agent-ecosystem)
            printf '%s\n' \
                "gcs-plt-gemop" \
                "gcs-plt-gembp" \
                "gcs-plt-tools"
            ;;
        *) return 1 ;;
    esac
}

print_usage() {
    cat <<'EOF'
Usage:
  bash gft-onboarding.sh --quickstart --workspace <workspace>
  bash gft-onboarding.sh --role <role-name>
  bash gft-onboarding.sh --sync-hooks

Workspaces:
  aethel
  gft-platform      (legacy aliases: evai-platform, studio-gencraft)
  onboarding        (legacy alias: workspace-ops)
  agent-ecosystem   (legacy alias: agent-factory)
EOF
}

parse_cli_args() {
    local quickstart="false"
    local workspace=""
    local role=""
    local sync_hooks="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quickstart)
                quickstart="true"
                shift
                ;;
            --workspace)
                if [[ -z "${2:-}" || "${2:0:1}" == "-" ]]; then
                    log_error "--workspace requires a value. Valid workspaces: $(format_valid_workspaces)"
                    return 1
                fi
                workspace="$2"
                shift 2
                ;;
            --workspace=*)
                workspace="${1#*=}"
                if [[ -z "$workspace" ]]; then
                    log_error "--workspace requires a value. Valid workspaces: $(format_valid_workspaces)"
                    return 1
                fi
                shift
                ;;
            --role)
                if [[ -z "${2:-}" || "${2:0:1}" == "-" ]]; then
                    log_error "--role requires a value."
                    return 1
                fi
                role="$2"
                shift 2
                ;;
            --role=*)
                role="${1#*=}"
                if [[ -z "$role" ]]; then
                    log_error "--role requires a value."
                    return 1
                fi
                shift
                ;;
            --sync-hooks)
                sync_hooks="true"
                shift
                ;;
            -h|--help)
                print_usage
                GFT_SHOW_HELP_ONLY="true"
                export GFT_SHOW_HELP_ONLY
                return 0
                ;;
            *)
                log_error "Unknown argument: $1"
                print_usage >&2
                return 1
                ;;
        esac
    done

    if [[ "$quickstart" == "true" ]]; then
        if [[ -z "$workspace" ]]; then
            log_error "--quickstart requires --workspace. Valid workspaces: $(format_valid_workspaces)"
            return 1
        fi
        if ! is_valid_workspace "$workspace"; then
            log_error "Unknown workspace '$workspace'. Valid workspaces: $(format_valid_workspaces)"
            return 1
        fi
        GFT_QUICKSTART="true"
        GFT_NON_INTERACTIVE="true"
        GFT_WORKSPACE="$(canonicalize_workspace "$workspace")"
        if [[ -z "$role" ]]; then
            role="$(workspace_role "$workspace")"
        fi
        export GFT_QUICKSTART GFT_NON_INTERACTIVE GFT_WORKSPACE
    elif [[ -n "$workspace" ]]; then
        if ! is_valid_workspace "$workspace"; then
            log_error "Unknown workspace '$workspace'. Valid workspaces: $(format_valid_workspaces)"
            return 1
        fi
        GFT_WORKSPACE="$(canonicalize_workspace "$workspace")"
        export GFT_WORKSPACE
    fi

    if [[ -n "$role" ]]; then
        GFT_ROLE="$role"
        export GFT_ROLE
    fi

    if [[ "$sync_hooks" == "true" ]]; then
        GFT_SYNC_HOOKS_ONLY="true"
        export GFT_SYNC_HOOKS_ONLY
    fi
}


# Fetches the version for a specific tool from the SSoT .tool-versions-gft file.
# $1: The name of the tool as it appears in the .tool-versions-gft file (e.g., "nodejs").
# Returns (echoes) the version string (e.g., "20.18.0").
get_ssot_tool_version() {
    local tool_name_in_ssot="$1"
    # GFT_SSOT_PATH is defined in 01_helpers.sh in the setup_ssot_repository function
    local ssot_versions_file="${GFT_SSOT_PATH}/tooling/ssot/.tool-versions-gft"

    if [ ! -f "$ssot_versions_file" ]; then
        log_error "SSoT versions file not found at: $ssot_versions_file"
        return 1
    fi

    # Find the line starting with the tool name, and print the second column.
    # The grep ensures we match the exact tool name at the beginning of the line.
    # || true prevents pipefail from propagating grep's exit-1 (no-match) as a function error.
    grep "^${tool_name_in_ssot} " "$ssot_versions_file" | awk '{print $2}' || true
}


check_prerequisites() {
    log_info "Checking and installing core dependencies (git, curl, yq, python3)..."
    local all_ok=true

    # List of essential tools and their package names.
    # Format: "command_to_check:package_name"
    local prerequisites=(
        "git:git"
        "curl:curl"
        "yq:yq"
        "python3:python3"
        "unzip:unzip"
    )

    for item in "${prerequisites[@]}"; do
        local cmd="${item%%:*}"
        local pkg="${item#*:}"

        if ! command -v "$cmd" &> /dev/null; then
            log_warn "Required tool '$cmd' is not installed. Attempting installation..."
            # Assumes install_with_package_manager is available (sourced before call)
            install_with_package_manager "$pkg" "$cmd"

            # Verify installation
            if ! command -v "$cmd" &> /dev/null; then
                log_error "Failed to automatically install '$cmd'. Please install it manually and re-run the script."
                all_ok=false
            fi
        else
            log_info "Prerequisite '$cmd' is present."
        fi
    done

    if ! $all_ok; then
        exit 1
    fi
    log_success "All prerequisite tools are installed and ready."
}

# --- SSoT Management ---

# Clones or pulls the gcs-core-governance repository to a temporary path.
# This ensures the script always uses the latest SSoT configuration.
setup_ssot_repository() {
    log_info "Setting up SSoT configuration repository..."
    if [ -d "$GFT_SSOT_PATH/.git" ]; then
        log_info "Updating existing SSoT repository at $GFT_SSOT_PATH..."
        run_command_with_logging git -C "$GFT_SSOT_PATH" pull --ff-only
    else
        # A path that exists but is not a git repo (stale/partial leftover) would
        # break `git pull` with 'fatal: not a git repository'. Remove and re-clone.
        if [ -e "$GFT_SSOT_PATH" ]; then
            log_warn "$GFT_SSOT_PATH exists but is not a git repository; removing and re-cloning."
            rm -rf "$GFT_SSOT_PATH"
        fi
        log_info "Cloning SSoT repository into $GFT_SSOT_PATH..."
        run_command_with_logging git clone --depth 1 "$GFT_SSOT_REPO" "$GFT_SSOT_PATH"
    fi
    log_success "SSoT repository is up to date."
}

# --- Shared Studio-Tooling Home (ENG-ADR-088 §3/§10) ---

# The three repos that install exactly ONCE into the shared studio-tooling home
# (ENG-ADR-088 Repository-Classification). Project repos live under
# GFT_PROJECTS_HOME instead. NOT readonly: this file is re-sourced during
# onboarding, and a readonly re-declaration would abort the source under set -e.
GFT_SHARED_TOOLING_REPOS=(gcs-plt-tools gcs-plt-gemop gcs-core-governance)

# Echoes the shared studio-tooling home directory. Defaults to ~/.gft-studio;
# override with GFT_STUDIO_HOME. Mirrors the gft CLI resolver (gcs-plt-tools
# WI-384a / #622) so the shell and Python halves agree on one location.
studio_home() {
    echo "${GFT_STUDIO_HOME:-$HOME/.gft-studio}"
}

# Warns ONCE per shell when the legacy ~/gft_studio layout exists, so returning
# users learn shared tooling has moved. MUST be called from the parent shell
# (never a subshell) or the once-guard will not persist. Initialized only if
# unset, so re-sourcing this file does not reset a warning that already fired.
: "${_GFT_LEGACY_WARNED:=0}"
warn_legacy_gft_studio() {
    [[ "$_GFT_LEGACY_WARNED" == "1" ]] && return 0
    if [[ -d "$HOME/gft_studio" ]]; then
        _GFT_LEGACY_WARNED=1
        log_warn "Legacy workspace ~/gft_studio detected — shared studio tooling now lives in $(studio_home) (ENG-ADR-088)."
        log_info "  Your project repos under ~/gft_studio are left untouched. If you previously set GFT_SSOT_GEMOP_PATH to a ~/gft_studio path, update it to $(studio_home)/gcs-plt-gemop or unset it to take the new default."
    fi
    return 0
}

# Installs the three shared-tooling repos into studio_home(), exactly once each,
# idempotently (ENG-ADR-088 §8). Reuses the setup_ssot_repository() decision
# pattern: existing git repo → pull --ff-only; non-git leftover → rm -rf + clone;
# absent → clone. Transport mirrors clone_repositories_for_role (gh when present,
# else git+SSH). Non-interactive: shared tooling is always required.
bootstrap_shared_tooling() {
    local home_dir; home_dir="$(studio_home)"
    log_info "Bootstrapping shared studio tooling into ${home_dir} ..."
    mkdir -p "$home_dir"
    chmod 0755 "$home_dir" 2>/dev/null || true

    # if-form (not `cmd && var=true`) so a missing gh never trips `set -e`.
    local gh_available=false
    if command -v gh &>/dev/null; then
        gh_available=true
    fi

    local repo target clone_ok
    for repo in "${GFT_SHARED_TOOLING_REPOS[@]}"; do
        target="${home_dir}/${repo}"
        if [[ -d "${target}/.git" ]]; then
            log_info "Updating shared repo '${repo}' at ${target} ..."
            if ! run_command_with_logging git -C "$target" pull --ff-only; then
                log_warn "Could not fast-forward '${repo}'; leaving the existing checkout in place."
            fi
            continue
        fi
        # A path that exists but is not a git repo (stale/partial leftover) would
        # break `git pull`. Remove and re-clone (never `[[ -d ]] || clone`).
        if [[ -e "$target" ]]; then
            log_warn "${target} exists but is not a git repository; removing and re-cloning."
            rm -rf "$target"
        fi
        log_info "Cloning shared repo '${repo}' into ${target} ..."
        # Direct invocation (NOT run_command_with_logging): the clone is non-fatal,
        # so a failure must not print a misleading [ERROR] line ahead of our [WARN]
        # + fix hint. Command output is captured to the run log.
        clone_ok=0
        if $gh_available; then
            gh repo clone "GenCr-ft/${repo}" "$target" >>"${LOG_FILE:-/dev/null}" 2>&1 || clone_ok=$?
        else
            git clone "git@github.com:GenCr-ft/${repo}.git" "$target" >>"${LOG_FILE:-/dev/null}" 2>&1 || clone_ok=$?
        fi
        # Non-fatal (matches the deferred-gft pattern): a single clone failure
        # must not abort onboarding — its consumers degrade gracefully.
        if [[ "$clone_ok" -ne 0 ]]; then
            log_warn "Could not clone shared repo '${repo}' (non-fatal). Install it later with:"
            log_info "  gh repo clone GenCr-ft/${repo} \"${target}\""
        else
            log_success "Cloned shared repo '${repo}'."
        fi
    done
    log_success "Shared studio tooling bootstrap complete in ${home_dir}."
}

# Loads the YAML content from the Role-Tooling matrix into a global variable.
load_ssot_configuration() {
    log_info "Loading role and tooling data from SSoT..."
    local start_ts; start_ts=$(date +%s)
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

    local end_ts; end_ts=$(date +%s)
    log_success "SSoT configuration loaded in $((end_ts - start_ts))s."
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

    if [[ -n "${GFT_ROLE:-}" ]]; then
        log_info "Auto-selecting role from GFT_ROLE: $GFT_ROLE" >&2
        echo "$GFT_ROLE"
        return 0
    fi

    log_info "Please select your primary role in the studio:" >&2
    # Use yq to parse roles from the global variable and format them for the `select` prompt.
    mapfile -t role_options < <(echo "$ROLE_MATRIX_YAML" | yq -r '.roles[] | select(.name != "common-base") | .name + ": " + .description')

    local selected_role_name
    select role_choice in "${role_options[@]}"; do
        if [[ -n "$role_choice" ]]; then
            selected_role_name=$(echo "$role_choice" | cut -d':' -f1)
            log_info "You have selected the role: $selected_role_name" >&2
            echo "$selected_role_name" # Return the value
            return 0
        else
            log_warn "Invalid selection. Please try again." >&2
        fi
    done
}
