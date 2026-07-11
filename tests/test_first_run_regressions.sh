#!/usr/bin/env bash
set -euo pipefail

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)

export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"

source "${PROJECT_ROOT}/gft-onboarding.sh"
eval "$(declare -f main | sed '1s/main/onboarding_main/')"

log_test() { echo "[TEST] $*"; }
fail() { echo "[FAIL] $*" >&2; return 1; }

ensure_runtime_mock_ssot() {
    [[ "$GFT_SSOT_PATH" != "$PROJECT_ROOT"* ]] || fail "runtime mock SSoT must not write into the checked-in repo"
    mkdir -p "$GFT_SSOT_PATH/tooling" "$GFT_SSOT_PATH/tooling/ssot" "$GFT_SSOT_PATH/foundations/governance"
    cp "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/tooling/ENG-STAN-002.environment-variable-standard.md" "$GFT_SSOT_PATH/tooling/ENG-STAN-002.environment-variable-standard.md"
    cp "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/tooling/ENG-STAN-003.vs-code-extension-recommendations.md" "$GFT_SSOT_PATH/tooling/ENG-STAN-003.vs-code-extension-recommendations.md"
    cp "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md" \
        "$GFT_SSOT_PATH/foundations/governance/GOV-GUIDE-010.role-tooling--resource-matrix.md"
    printf 'nodejs lts-gallium\npython 3.11.5\nopentofu 1.6.0\n' > "$GFT_SSOT_PATH/tooling/ssot/.tool-versions-gft"
    printf 'public.ecr.aws/docker/library/node:20\n' > "$GFT_SSOT_PATH/tooling/ssot/.docker-images-gft"
}

load_mock_role_matrix() {
    local mock_matrix_path="${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md"
    ROLE_MATRIX_YAML=$(sed -n '/```yaml/,/```/p' "$mock_matrix_path" | sed '1d;$d')
    export ROLE_MATRIX_YAML
}

test_detect_os_is_available_to_main() {
    log_test "detect_os is defined for main orchestration"
    declare -f detect_os_arch >/dev/null || fail "detect_os_arch is not defined"
}

test_role_selection_stdout_is_role_only() {
    log_test "GFT_ROLE selection writes only the role to stdout"
    load_mock_role_matrix

    local stdout_file stderr_file selected stderr_output
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)

    GFT_ROLE=devops-specialist select_user_role >"$stdout_file" 2>"$stderr_file"
    selected=$(<"$stdout_file")
    stderr_output=$(<"$stderr_file")

    rm -f "$stdout_file" "$stderr_file"

    [[ "$selected" == "devops-specialist" ]] || fail "expected exact role on stdout, got: $selected"
    [[ "$stderr_output" == *"Auto-selecting role from GFT_ROLE"* ]] || fail "expected role selection log on stderr"
}

test_cli_rejects_empty_role_without_abort_trap() {
    log_test "CLI parsing rejects empty --role without unexpected-abort trap"

    local tmp_home stdout_file stderr_file status
    tmp_home=$(mktemp -d)
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)

    HOME="$tmp_home" bash "$PROJECT_ROOT/gft-onboarding.sh" --role= >"$stdout_file" 2>"$stderr_file"
    status=$?

    [[ "$status" -eq 2 ]] || {
        local output
        output=$(cat "$stdout_file" "$stderr_file")
        rm -rf "$tmp_home" "$stdout_file" "$stderr_file"
        fail "expected exit 2 for empty role, got $status: $output"
        return 1
    }
    ! grep -q "Onboarding aborted unexpectedly" "$stderr_file" || {
        local output
        output=$(cat "$stdout_file" "$stderr_file")
        rm -rf "$tmp_home" "$stdout_file" "$stderr_file"
        fail "parse error triggered unexpected-abort trap: $output"
        return 1
    }

    rm -rf "$tmp_home" "$stdout_file" "$stderr_file"
}

test_configure_environment_variables_accepts_one_argument_under_nounset() {
    log_test "configure_environment_variables accepts one argument under set -u"
    local tmp_home
    tmp_home=$(mktemp -d)
    ensure_runtime_mock_ssot

    (
        set -u
        export HOME="$tmp_home"
        configure_environment_variables "devops-specialist" >/tmp/gft-env-config.out 2>/tmp/gft-env-config.err
    ) || {
        local err
        err=$(cat /tmp/gft-env-config.err 2>/dev/null || true)
        rm -rf "$tmp_home" /tmp/gft-env-config.out /tmp/gft-env-config.err
        fail "configure_environment_variables failed with one argument: $err"
        return 1
    }

    [[ -f "$tmp_home/.bashrc" ]] || {
        rm -rf "$tmp_home" /tmp/gft-env-config.out /tmp/gft-env-config.err
        fail "expected .bashrc to be created"
        return 1
    }

    rm -rf "$tmp_home" /tmp/gft-env-config.out /tmp/gft-env-config.err
}

test_setup_ssh_key_creates_ssh_directory() {
    log_test "setup_ssh_key creates ~/.ssh before key generation"
    local tmp_home original_home
    tmp_home=$(mktemp -d)
    original_home="$HOME"

    confirm_action() { return 1; }

    export HOME="$tmp_home"
    git config --global user.email "test@example.com"

    setup_ssh_key >/tmp/gft-ssh-key.out 2>/tmp/gft-ssh-key.err || {
        local err
        err=$(cat /tmp/gft-ssh-key.err 2>/dev/null || true)
        export HOME="$original_home"
        rm -rf "$tmp_home" /tmp/gft-ssh-key.out /tmp/gft-ssh-key.err
        fail "setup_ssh_key failed: $err"
        return 1
    }

    [[ -f "$tmp_home/.ssh/id_ed25519" ]] || {
        export HOME="$original_home"
        rm -rf "$tmp_home" /tmp/gft-ssh-key.out /tmp/gft-ssh-key.err
        fail "expected SSH private key to be created"
        return 1
    }

    export HOME="$original_home"
    rm -rf "$tmp_home" /tmp/gft-ssh-key.out /tmp/gft-ssh-key.err
}

test_setup_ssh_key_handles_missing_git_email() {
    log_test "setup_ssh_key handles missing git user.email"
    local tmp_home original_home
    tmp_home=$(mktemp -d)
    original_home="$HOME"

    confirm_action() { return 1; }

    export HOME="$tmp_home"

    setup_ssh_key >/tmp/gft-ssh-fallback.out 2>/tmp/gft-ssh-fallback.err || {
        local err
        err=$(cat /tmp/gft-ssh-fallback.err 2>/dev/null || true)
        export HOME="$original_home"
        rm -rf "$tmp_home" /tmp/gft-ssh-fallback.out /tmp/gft-ssh-fallback.err
        fail "setup_ssh_key failed without git email: $err"
        return 1
    }

    [[ -f "$tmp_home/.ssh/id_ed25519" ]] || {
        export HOME="$original_home"
        rm -rf "$tmp_home" /tmp/gft-ssh-fallback.out /tmp/gft-ssh-fallback.err
        fail "expected SSH key with fallback comment"
        return 1
    }

    export HOME="$original_home"
    rm -rf "$tmp_home" /tmp/gft-ssh-fallback.out /tmp/gft-ssh-fallback.err
}

test_clone_repositories_uses_gft_projects_home() {
    log_test "clone_repositories_for_role uses GFT_PROJECTS_HOME"
    load_mock_role_matrix

    local tmp_home tmp_workspace original_home original_workspace
    tmp_home=$(mktemp -d)
    tmp_workspace=$(mktemp -d)
    original_home="$HOME"
    original_workspace="${GFT_PROJECTS_HOME:-}"

    confirm_action() { return 0; }
    gh() {
        if [[ "${1:-}" == "repo" && "${2:-}" == "view" ]]; then
            echo 1
            return 0
        fi
        if [[ "${1:-}" == "repo" && "${2:-}" == "clone" ]]; then
            mkdir -p "$4"
            return 0
        fi
        return 0
    }

    export HOME="$tmp_home"
    export GFT_PROJECTS_HOME="$tmp_workspace"
    # A project repo — shared tooling (gcs-plt-*) now installs into studio_home()
    # and is skipped by clone_repositories_for_role (ENG-ADR-088 §3 / WI-384b).
    MOCK_ROLE_REPO_OUTPUT="gencraft-iac"

    clone_repositories_for_role "devops-specialist" >/tmp/gft-clone.out 2>/tmp/gft-clone.err || {
        local err
        err=$(cat /tmp/gft-clone.err 2>/dev/null || true)
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-clone.out /tmp/gft-clone.err
        fail "clone_repositories_for_role failed: $err"
        return 1
    }

    [[ -d "$tmp_workspace/gencraft-iac" ]] || {
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-clone.out /tmp/gft-clone.err
        fail "expected repositories under GFT_PROJECTS_HOME"
        return 1
    }
    [[ ! -d "$tmp_home/gft_studio/gencraft-iac" ]] || {
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-clone.out /tmp/gft-clone.err
        fail "repositories were cloned under HOME/gft_studio instead of GFT_PROJECTS_HOME"
        return 1
    }

    export HOME="$original_home"
    export GFT_PROJECTS_HOME="$original_workspace"
    rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-clone.out /tmp/gft-clone.err
}

test_configure_env_expands_projects_home() {
    log_test "configure_environment_variables expands ~ and literal \$HOME in GFT_PROJECTS_HOME"
    local tmp_home original_home tmp_profile eng_stan_path original_eng_stan
    tmp_home=$(mktemp -d)
    tmp_profile=$(mktemp)
    original_home="$HOME"

    ensure_runtime_mock_ssot
    eng_stan_path=$(find "$GFT_SSOT_PATH" -type f -name "ENG-STAN-002.environment-variable-standard.md" | head -1)
    original_eng_stan=$(<"$eng_stan_path")

    _cleanup_expand_test() {
        export HOME="$original_home"
        echo "$original_eng_stan" > "$eng_stan_path"
        rm -rf "$tmp_home" "$tmp_profile"
    }

    export HOME="$tmp_home"

    # --- Tilde expansion: ~/tilde_studio → $tmp_home/tilde_studio ---
    cat > "$eng_stan_path" <<'SSOT_EOF'
# Environment Variable Standard

## Common Variables
```env
GFT_PROJECTS_HOME="~/tilde_studio"
```
SSOT_EOF
    configure_environment_variables "devops-specialist" "$tmp_profile" >/dev/null 2>&1 || true
    if [[ ! -d "$tmp_home/tilde_studio" ]]; then
        _cleanup_expand_test
        fail "tilde GFT_PROJECTS_HOME did not expand: $tmp_home/tilde_studio was not created"
        return 1
    fi

    # Truncate profile so the idempotency guard doesn't skip the second assertion
    : > "$tmp_profile"

    # --- Literal $HOME expansion: $HOME/dollar_studio → $tmp_home/dollar_studio ---
    cat > "$eng_stan_path" <<'SSOT_EOF'
# Environment Variable Standard

## Common Variables
```env
GFT_PROJECTS_HOME="$HOME/dollar_studio"
```
SSOT_EOF
    configure_environment_variables "devops-specialist" "$tmp_profile" >/dev/null 2>&1 || true
    if [[ ! -d "$tmp_home/dollar_studio" ]]; then
        _cleanup_expand_test
        fail "literal \$HOME GFT_PROJECTS_HOME did not expand: $tmp_home/dollar_studio was not created"
        return 1
    fi

    _cleanup_expand_test
}

test_documented_filenames_match_repo_files() {
    log_test "documented filenames match repo files"

    ! grep -R "validate-gft-devops-environment.sh" README.md docs AGENTS.md >/tmp/gft-doc-grep.out 2>/dev/null || {
        local matches
        matches=$(cat /tmp/gft-doc-grep.out)
        rm -f /tmp/gft-doc-grep.out
        fail "stale validator filename documented: $matches"
    }
    ! grep -R "gft_onboarding.sh" onboarding-win.ps1 README.md docs AGENTS.md >/tmp/gft-doc-grep.out 2>/dev/null || {
        local matches
        matches=$(cat /tmp/gft-doc-grep.out)
        rm -f /tmp/gft-doc-grep.out
        fail "stale onboarding filename documented: $matches"
    }

    rm -f /tmp/gft-doc-grep.out
}

test_readme_does_not_advertise_missing_standalone_artifacts() {
    log_test "README does not advertise missing standalone artifacts"

    ! grep -q "gft-onboarding.sh.sha256" README.md || fail "README references missing gft-onboarding.sh.sha256"
    ! grep -q "onboarding-win.ps1.sha256" README.md || fail "README references missing onboarding-win.ps1.sha256"
    ! grep -q "raw.githubusercontent.com/GenCr-ft/gcd-onboarding-scripts/main/gft-onboarding.sh" README.md || \
        fail "README advertises unsupported standalone gft-onboarding.sh download"
}

test_main_smoke_uses_isolated_workspace() {
    log_test "main smoke run completes with isolated HOME and GFT_PROJECTS_HOME"
    ensure_runtime_mock_ssot
    load_mock_role_matrix

    local tmp_home tmp_workspace original_home original_workspace original_path
    tmp_home=$(mktemp -d)
    tmp_workspace=$(mktemp -d)
    original_home="$HOME"
    original_workspace="${GFT_PROJECTS_HOME:-}"
    original_path="$PATH"

    install_tools_for_role() { log_info "SMOKE: skipping tool install for $1"; }
    setup_ssot_repository() { log_info "SMOKE: using runtime mock SSoT"; }
    install_gft_ops_scripts() { log_info "SMOKE: skipping pipx install"; }
    performance_and_caching() { log_info "SMOKE: skipping Docker cache"; }
    final_validation() { log_info "SMOKE: skipping final external validation"; }

    gh() {
        if [[ "${1:-}" == "ssh-key" && "${2:-}" == "add" ]]; then
            return 0
        fi
        if [[ "${1:-}" == "repo" && "${2:-}" == "view" ]]; then
            echo 1
            return 0
        fi
        if [[ "${1:-}" == "repo" && "${2:-}" == "clone" ]]; then
            mkdir -p "$4"
            if [[ "$3" == "GenCr-ft/gcs-plt-tools" ]]; then
                cat > "$4/onboard.sh" <<'MOCK'
#!/usr/bin/env bash
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/gft" <<'INNER'
#!/usr/bin/env bash
if [[ "${1:-}" == "version" ]]; then
    echo "smoke-gft"
    exit 0
fi
INNER
chmod +x "$HOME/.local/bin/gft"
MOCK
                chmod +x "$4/onboard.sh"
            fi
            return 0
        fi
        return 0
    }

    export HOME="$tmp_home"
    git config --global user.name "Smoke Test"
    git config --global user.email "smoke@example.com"
    export GFT_PROJECTS_HOME="$tmp_workspace"
    export GFT_NON_INTERACTIVE=true
    export GFT_ROLE=devops-specialist
    export PATH="/usr/bin:/bin:$original_path"

    onboarding_main >/tmp/gft-main-smoke.out 2>/tmp/gft-main-smoke.err || {
        local err
        err=$(cat /tmp/gft-main-smoke.err 2>/dev/null || true)
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        export PATH="$original_path"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-main-smoke.out /tmp/gft-main-smoke.err
        fail "main smoke failed: $err"
        return 1
    }

    # Shared tooling installs once into studio_home() (~/.gft-studio), NOT the
    # project workspace (ENG-ADR-088 §3 / WI-384b).
    [[ -d "$tmp_home/.gft-studio/gcs-plt-tools" ]] || {
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        export PATH="$original_path"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-main-smoke.out /tmp/gft-main-smoke.err
        fail "expected gcs-plt-tools under studio_home() (~/.gft-studio)"
        return 1
    }
    [[ ! -d "$tmp_workspace/gcs-plt-tools" ]] || {
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        export PATH="$original_path"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-main-smoke.out /tmp/gft-main-smoke.err
        fail "shared tooling gcs-plt-tools must NOT be cloned into GFT_PROJECTS_HOME"
        return 1
    }
    [[ ! -d "$tmp_home/gft_studio/gcs-plt-tools" ]] || {
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        export PATH="$original_path"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-main-smoke.out /tmp/gft-main-smoke.err
        fail "main smoke cloned repositories under legacy HOME/gft_studio"
        return 1
    }
    [[ -x "$tmp_home/.local/bin/gft" ]] || {
        export HOME="$original_home"
        export GFT_PROJECTS_HOME="$original_workspace"
        export PATH="$original_path"
        rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-main-smoke.out /tmp/gft-main-smoke.err
        fail "expected delegated gft wrapper to be installed"
        return 1
    }

    export HOME="$original_home"
    export GFT_PROJECTS_HOME="$original_workspace"
    export PATH="$original_path"
    unset GFT_NON_INTERACTIVE GFT_ROLE
    rm -rf "$tmp_home" "$tmp_workspace" /tmp/gft-main-smoke.out /tmp/gft-main-smoke.err
}

run_tests() {
    local failed=0
    test_detect_os_is_available_to_main || ((failed+=1))
    test_role_selection_stdout_is_role_only || ((failed+=1))
    test_cli_rejects_empty_role_without_abort_trap || ((failed+=1))
    test_configure_environment_variables_accepts_one_argument_under_nounset || ((failed+=1))
    test_setup_ssh_key_creates_ssh_directory || ((failed+=1))
    test_setup_ssh_key_handles_missing_git_email || ((failed+=1))
    test_clone_repositories_uses_gft_projects_home || ((failed+=1))
    test_configure_env_expands_projects_home || ((failed+=1))
    test_documented_filenames_match_repo_files || ((failed+=1))
    test_readme_does_not_advertise_missing_standalone_artifacts || ((failed+=1))
    test_main_smoke_uses_isolated_workspace || ((failed+=1))

    if [[ "$failed" -ne 0 ]]; then
        echo "[FAIL] $failed first-run regression test(s) failed" >&2
        exit 1
    fi

    echo "[OK] first-run regression tests passed"
}

run_tests "$@"
