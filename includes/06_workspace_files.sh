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
WRAPPER_VERSION="3"

#: Exit status the wrapper uses for "the linter could not run", distinct from the linter's
#: own 0 (compliant) and 1 (violation).
#:
#: A third code is not decoration: a ModuleNotFoundError crash and a genuine violation BOTH
#: exit 1, so "could not run" cannot be recovered from the linter's status after the fact.
#: Establishing it is the whole reason the diagnosis fix and the interpreter fix are one
#: change. 3 avoids 1 (verdict), 2 (shell usage) and 126/127 (exec faults).
GATE_EXIT_CANNOT_RUN=3

#: The linter's only third-party import. Named here so the coupling is in ONE place.
#:
#: Overridable so the CANNOT-RUN branch is reachable in tests: `/usr/bin/python3` is a fixed
#: candidate and carries PyYAML on the dev machine and the self-hosted CI runner, so an arm
#: cannot reach that branch by manipulating PATH. A branch that cannot be exercised is a
#: branch that is not tested. It becomes dead weight once every clone has an installed
#: entry point, which is the primary path below.
#:
#: Read at GENERATION time (inside deploy_planning_metadata_hook), not here: this file is
#: sourced once at startup, so resolving the override here would bake whatever the
#: environment held at source time and silently ignore a later change.
LINTER_REQUIRED_MODULE="yaml"

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

    # ── Interpreter resolution ────────────────────────────────────────────────────────
    #
    # The wrapper used to exec `"$linter_src" "$@"`, so the interpreter came from the
    # linter's `#!/usr/bin/env python3` -> PATH. That made a GOVERNANCE GATE's answer a
    # function of the developer's shell: on the dev machine
    # /home/lgan/.gft-studio/.poetry/bin/python3 (no PyYAML) resolves BEFORE
    # /usr/bin/python3 (PyYAML 6.0.3), so the same commit passed one hour and was
    # hard-blocked the next (#272, and #271 which reported the same defect first).
    #
    # The pin already exists and was simply not being called: gcd-ops-scripts declares
    # `PyYAML = ">=6.0.2"` and ships a `validate-planning-metadata` console script whose
    # shebang is an ABSOLUTE path into the environment that declares it -- it runs with
    # PATH emptied. Preferring it puts the pin where the dependency is declared, instead
    # of mirroring another repo's pyproject.toml in shell here.
    #
    # Deliberately NOT done: changing the linter's own shebang. `#!/usr/bin/env python3`
    # is correct for a source module in a package; an absolute path there would break the
    # repo's own venv, its CI, and macOS. A shebang cannot express "the interpreter that
    # has my dependencies" -- an entry point is exactly that mechanism.
    # Resolved from target_dir ONLY, never via `command -v`.
    #
    # An earlier revision also accepted `command -v validate-planning-metadata`, and it was
    # wrong twice over. It re-introduced ambient resolution through a different variable --
    # a stale global install would be preferred over this workspace's own clone -- and it
    # let source and execution disagree: `linter_src` is resolved from target_dir, so an
    # entry point from somewhere else could be an entirely different revision of the
    # linter than the file this wrapper claims to run. It was caught by the fixture arms,
    # which found the DEVELOPER'S REAL linter on PATH and ran it against a mock workspace.
    #
    # The rule: always execute the linter belonging to this workspace. Entry point from
    # this clone if installed, else this clone's source under a probed interpreter.
    local linter_entry="${target_dir}/gcd-ops-scripts/.venv/bin/validate-planning-metadata"
    [[ -x "$linter_entry" ]] || linter_entry=""

    local linter_req="${GFT_LINTER_REQUIRED_MODULE:-${LINTER_REQUIRED_MODULE}}"

    # Fallback candidates, used only when no entry point is installed (a clone with the
    # source tree and no `poetry install`). Each is PROBED for the requirement before use;
    # an interpreter that cannot import it is not a candidate, so the crash cannot occur.
    # Ordered for determinism over ambient preference, which is the point of this WI:
    # the linter's own venv, then a fixed absolute path, then PATH as a last resort.
    local linter_venv_py="${target_dir}/gcd-ops-scripts/.venv/bin/python3"
    [[ -x "$linter_venv_py" ]] || linter_venv_py=""
    local linter_path_py
    linter_path_py="$(command -v python3 2>/dev/null || true)"

    if [[ -n "$linter_entry" ]]; then
        log_info "  Planning linter entry point: ${linter_entry}"
    else
        log_warn "  No validate-planning-metadata entry point found; the wrapper will probe an interpreter for '${linter_req}'."
        log_warn "  Install it once with: (cd ${target_dir}/gcd-ops-scripts && poetry install)"
    fi

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

# 1. Run strict planning metadata validation.
#
# Resolved at generation time so the gate's answer does not depend on the shell's PATH.
GATE_CANNOT_RUN=${GATE_EXIT_CANNOT_RUN}
LINTER_ENTRY="${linter_entry}"
LINTER_SRC="${linter_src}"
LINTER_REQ="${linter_req}"
LINTER_VENV_PY="${linter_venv_py}"
LINTER_PATH_PY="${linter_path_py}"

run_linter() {
    # Primary: the installed console script. Its shebang is an absolute interpreter path
    # into the environment that declares the linter's dependencies, so PATH plays no part.
    if [ -n "\$LINTER_ENTRY" ] && [ -x "\$LINTER_ENTRY" ]; then
        "\$LINTER_ENTRY" "\$@"
        return \$?
    fi

    # Documented fallback: no entry point installed. PROBE each candidate for the
    # requirement and use the first that satisfies it. Never a bare \`python3\` -- that is
    # today's behaviour and the whole defect.
    GATE_TRIED=""
    for py in "\${GFT_LINTER_PYTHON:-}" "\$LINTER_VENV_PY" /usr/bin/python3 "\$LINTER_PATH_PY"; do
        [ -n "\$py" ] && [ -x "\$py" ] || continue
        case " \$GATE_TRIED " in *" \$py "*) continue ;; esac
        GATE_TRIED="\$GATE_TRIED \$py"
        if "\$py" -c "import \$LINTER_REQ" >/dev/null 2>&1; then
            "\$py" "\$LINTER_SRC" "\$@"
            return \$?
        fi
    done

    # Nothing can run it. Fail CLOSED -- an unrunnable gate must not wave a commit
    # through -- but say what actually happened. "The check said no" and "the check could
    # not run" must not print the same sentence.
    {
        echo "[TRACEABILITY GATE] CANNOT RUN — the planning metadata linter was not executed."
        echo "  Your commit has NOT been judged. This is not a validation failure."
        echo "  Missing requirement: python module '\$LINTER_REQ'"
        echo "  Interpreters tried:\${GATE_TRIED:- (none executable)}"
        echo "  Entry point looked for: \${LINTER_ENTRY:-<none installed>}"
        echo "  Fix: (cd ${target_dir}/gcd-ops-scripts && poetry install)"
        echo "  Or:  set GFT_LINTER_PYTHON to an interpreter that has '\$LINTER_REQ'."
    } >&2
    return \$GATE_CANNOT_RUN
}

run_linter "\$@"
LINTER_EXIT=\$?

if [ \$LINTER_EXIT -eq \$GATE_CANNOT_RUN ]; then
    # run_linter already explained itself; do not relabel it as a verdict.
    exit \$LINTER_EXIT
fi

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
