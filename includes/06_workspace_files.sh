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

#: The wrapper's identity marker, and its VERSION.
#:
#: The version is load-bearing, not decoration. The skip branch below used to grep the marker
#: alone, so a clone carrying an OLD wrapper with no legacy hook was skipped forever — and that
#: was exactly the population needing repair: measured across 34 clones, 30 carried the wrapper
#: with no legacy and therefore failed open, and re-running onboarding could not fix any of them.
#: Bump WRAPPER_VERSION whenever the generated body changes semantics.
WRAPPER_MARKER="GenCr@ft Studio - Chained Pre-Commit Hook wrapper"
WRAPPER_VERSION="2"

deploy_planning_metadata_hook() {
    local target_dir="${GFT_PROJECTS_HOME:-${HOME}/gft_studio}"
    log_info "Deploying central planning metadata pre-commit hook..."

    # Canonical linter script path (resolved relative to the side-by-side repo layout)
    local linter_src="${target_dir}/gcd-ops-scripts/src/gft_ops_scripts/linters/validate_planning_metadata.py"

    # In a testing/mock environment, locate under target_dir as well
    if [[ ! -f "$linter_src" && -d "${target_dir}/linters" ]]; then
        linter_src="${target_dir}/linters/validate_planning_metadata.py"
    fi

    if [[ ! -f "$linter_src" ]]; then
        log_warn "Planning linter script not found at ${linter_src}. Skipping symlink hook deployment."
        return 0
    fi

    # Ensure the script is executable
    chmod +x "$linter_src"

    local deployed=0 skipped=0 failed=0
    # commit-msg outcomes are tracked apart from `failed`: they must not change this
    # function's exit status. See the note at the install site.
    local cm_installed=0 cm_failed=0 cm_absent=0

    # Scan all directories in target_dir to find Git repositories
    for repo_path in "${target_dir}"/*; do
        [[ -e "$repo_path" ]] || continue
        if [[ -d "${repo_path}/.git" ]]; then
            local repo_name
            repo_name=$(basename "$repo_path")
            local hook_dir="${repo_path}/.git/hooks"
            local hook_dest="${hook_dir}/pre-commit"
            local legacy_hook="${hook_dir}/pre-commit.legacy"

            mkdir -p "$hook_dir"

            # Skip only a CURRENT-version wrapper. Matching the marker alone meant an old
            # wrapper was skipped rather than upgraded, which is why 30 of 34 clones stayed
            # fail-open across every onboarding run.
            if [[ -f "$hook_dest" ]]; then
                if grep -q "wrapper-version: ${WRAPPER_VERSION}\$" "$hook_dest" 2>/dev/null; then
                    if [[ ! -f "$legacy_hook" ]]; then
                        skipped=$((skipped + 1))
                        continue
                    fi
                fi
            fi

            # Handle existing hooks to enable chaining
            if [[ -f "$hook_dest" && ! -L "$hook_dest" ]]; then
                # Never move our own wrapper to legacy: the wrapper's delegate path is baked in
                # at generation time, so a wrapper sitting at `pre-commit.legacy` is a wrapper
                # that calls itself. `pre-commit install` does exactly this move, which is how
                # `gencr-ft.github.io` came to hold our wrapper at that path.
                if ! grep -q "$WRAPPER_MARKER" "$hook_dest" 2>/dev/null; then
                    mv "$hook_dest" "$legacy_hook"
                    log_info "  Chained existing pre-commit hook in ${repo_name} to pre-commit.legacy"
                fi
            fi

            # Create the chained wrapper
            cat << EOF > "$hook_dest"
#!/usr/bin/env bash
# ${WRAPPER_MARKER}
# Automatically generated by onboarding scripts. Do not edit in place.
# wrapper-version: ${WRAPPER_VERSION}

# 1. Run strict planning metadata validation
"${linter_src}" "\$@"
LINTER_EXIT=\$?

if [ \$LINTER_EXIT -ne 0 ]; then
    echo "[TRACEABILITY GATE] Planning metadata validation failed. Commit aborted."
    exit \$LINTER_EXIT
fi

# 2. Run the repository's declared hook set.
#
# Graduated deliberately. A wrapper that exits 0 here silently skips every declared hook --
# which is what 30 of 34 clones did, three secret scanners among them. A wrapper that fails
# closed on everything blocks commits in every repo, which is a worse outage than the gap.
if [ -x "${legacy_hook}" ]; then
    # Refuse to delegate to ourselves. The path below is baked in at generation time, and
    # \`pre-commit install --hook-type pre-commit\` MOVES an existing hook there -- so if that
    # ran after deployment, the delegate is this wrapper and delegating recurses without
    # bound (measured at 7 levels, running the full hook set at each).
    if grep -q "${WRAPPER_MARKER}" "${legacy_hook}" 2>/dev/null; then
        echo "[TRACEABILITY GATE] refusing to delegate: ${legacy_hook} is this wrapper (self-delegation)." >&2
        echo "  Cause: 'pre-commit install --hook-type pre-commit' moved the wrapper aside." >&2
        echo "  Fix:   rm '${legacy_hook}' and re-run onboarding; install only --hook-type commit-msg." >&2
        exit 1
    fi
    echo "[TRACEABILITY GATE] Planning validation passed. Delegating to standard pre-commit hooks..."
    "${legacy_hook}" "\$@"
    exit \$?
fi

REPO_ROOT=\$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [ -f "\${REPO_ROOT}/.pre-commit-config.yaml" ]; then
    if command -v pre-commit >/dev/null 2>&1; then
        pre-commit run --hook-stage pre-commit
        exit \$?
    fi
    # A declared hook set that cannot run is a real misconfiguration, not an empty one:
    # passing here would give a developer with a broken toolchain the same green as one
    # with a working install.
    echo "[TRACEABILITY GATE] .pre-commit-config.yaml declares hooks but 'pre-commit' is not on PATH." >&2
    echo "  Install it:  pip install pre-commit   (or: pipx install pre-commit)" >&2
    echo "  Commit aborted rather than silently skipping the declared hooks." >&2
    exit 1
fi

# Nothing is declared, so there is nothing to skip.
exit 0
EOF
            chmod +x "$hook_dest"

            # The commit-msg stage, which nothing installed: 0 of 34 clones had it, so
            # \`commitlint\` had never run. Install ONLY this hook type -- installing the
            # pre-commit type would move our wrapper to .legacy and create the self-call loop
            # guarded against above. \`pre-commit install\` has no -C and needs cwd inside the
            # repo, hence the subshell.
            # Counted SEPARATELY from `failed`, and deliberately NOT folded into the return
            # code. `command -v pre-commit` can succeed while running it fails: its shebang is
            # /usr/bin/python3 and its module lives under ~/.local/lib, so any environment with
            # a relocated HOME finds the binary and gets ModuleNotFoundError. Folding that in
            # made this function return non-zero on an otherwise successful deployment, which
            # broke the contract tests/test_workspace_files.sh already asserts ("exits 0 on
            # success") and would abort onboarding on every such machine.
            #
            # The wrapper is the security-critical artefact and it deployed. A missing
            # commit-msg stage is reported loudly rather than by failing the run.
            if command -v pre-commit >/dev/null 2>&1; then
                if ( cd "$repo_path" && pre-commit install --hook-type commit-msg >/dev/null 2>&1 ); then
                    log_info "  commit-msg stage installed in ${repo_name}"
                    cm_installed=$((cm_installed + 1))
                else
                    log_warn "  commit-msg stage NOT installed in ${repo_name} — run 'pre-commit install --hook-type commit-msg' there once its toolchain works"
                    cm_failed=$((cm_failed + 1))
                fi
            else
                cm_absent=$((cm_absent + 1))
            fi

            deployed=$((deployed + 1))
        fi
    done

    log_success "Pre-commit hooks deployed: ${deployed} wrapper(s) installed, ${skipped} skipped, ${failed} failed."
    # Reported, never folded into the exit status. A summary that counted these as failures
    # would abort onboarding wherever `pre-commit` is present but unrunnable.
    if (( cm_failed > 0 || cm_absent > 0 )); then
        log_warn "commit-msg stage: ${cm_installed} installed, ${cm_failed} failed, ${cm_absent} skipped (pre-commit not on PATH)."
    else
        log_info "commit-msg stage: ${cm_installed} installed."
    fi
    return "$failed"
}
