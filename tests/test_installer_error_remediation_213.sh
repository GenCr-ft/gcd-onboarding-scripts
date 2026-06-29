#!/usr/bin/env bash
# Test suite for WI-213: install_rustup, cargo tools, commitlint, hook_managers,
# opentofu dispatcher, and configure_gft_cli error-handling & remediation guidance.

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"
export GFT_SSOT_PATH="${TEST_SCRIPT_PATH}/fixtures/mock_ssot"

source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
source "${PROJECT_ROOT}/includes/01_helpers.sh"
source "${PROJECT_ROOT}/includes/02_installers.sh"
source "${PROJECT_ROOT}/includes/03_configuration.sh"

# Stubs for functions not under test
confirm_action() { return 0; }
get_ssot_tool_version() {
    case "$1" in nodejs) echo "lts-iron" ;; python) echo "3.11.5" ;; opentofu) echo "1.6.0" ;; *) echo "" ;; esac
}
detect_os_arch() { GFT_OS="linux"; GFT_ARCH="amd64"; export GFT_OS GFT_ARCH; }

# ==============================================================================
# Cycle 1 — AC-1: curl|sh fails → [ERROR] + rustup.rs URL, no [SUCCESS]
# ==============================================================================
test_install_rustup_curl_failure() {
    local checks_failed=0
    local tmp_home; tmp_home=$(mktemp -d)
    trap 'rm -rf "$tmp_home"' RETURN

    # Stub curl to fail; isolate HOME so .cargo/env is absent
    curl() { return 1; }
    export -f curl

    local output
    # pipefail: make the curl|sh pipeline honour curl's exit code
    output=$(set -o pipefail; HOME="$tmp_home" PATH="/usr/bin:/bin" install_rustup 2>&1) || true

    unset -f curl

    [[ "$output" == *"https://rustup.rs"* ]] || \
        { log_error "FAIL: AC-1: expected https://rustup.rs in output; got: $output"; ((checks_failed++)); }
    [[ "$output" != *"Rust stable toolchain installed"* ]] || \
        { log_error "FAIL: AC-1: success message must not appear; got: $output"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] install_rustup curl failure: PASSED"
}

# ==============================================================================
# Cycle 2 — AC-2+AC-3: rustup chains fail → no success message, error emitted
# ==============================================================================
test_install_rustup_chains_failure() {
    local checks_failed=0

    # AC-2: new-install path — rustup absent from PATH; curl succeeds; .cargo/env
    # defines a rustup() that fails on 'target add'.
    local tmp_home; tmp_home=$(mktemp -d)
    trap 'rm -rf "$tmp_home"' RETURN
    curl() { return 0; }
    export -f curl
    mkdir -p "$tmp_home/.cargo"
    printf 'rustup() { [[ "${1:-}" == "target" ]] && return 1; return 0; }\nexport -f rustup\n' \
        > "$tmp_home/.cargo/env"

    local output
    output=$(set -o pipefail; HOME="$tmp_home" PATH="/usr/bin:/bin" install_rustup 2>&1) || true

    unset -f curl rustup

    [[ "$output" != *"Rust stable toolchain installed"* ]] || \
        { log_error "FAIL: AC-2: success message must not appear when target add fails; got: $output"; ((checks_failed++)); }
    [[ "$output" == *"target add wasm32-unknown-unknown"*"failed"* ]] || \
        { log_error "FAIL: AC-2: error message must appear when target add fails; got: $output"; ((checks_failed++)); }

    # AC-3: existing-rustup path — rustup update fails
    rustup() { return 1; }
    export -f rustup

    local output3
    output3=$(install_rustup 2>&1) || true

    unset -f rustup

    [[ "$output3" != *"Rust toolchain updated"* ]] || \
        { log_error "FAIL: AC-3: success message must not appear when rustup update fails; got: $output3"; ((checks_failed++)); }
    [[ "$output3" == *"update failed"* ]] || \
        { log_error "FAIL: AC-3: error message must appear when rustup update fails; got: $output3"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] install_rustup chains failure: PASSED"
}

# ==============================================================================
# --- Test Runner ---
# ==============================================================================
# ==============================================================================
# Cycle 3 — AC-4: cargo install fails → no success, [ERROR] present
# ==============================================================================
test_cargo_install_failure() {
    local checks_failed=0

    cargo() { return 1; }
    export -f cargo

    # Restrict PATH to exclude ~/.cargo/bin so already-installed checks do not short-circuit
    local output_wp output_wbc
    output_wp=$(PATH="/usr/bin:/bin" install_wasm_pack 2>&1) || true
    output_wbc=$(PATH="/usr/bin:/bin" install_wasm_bindgen_cli 2>&1) || true

    unset -f cargo

    [[ "$output_wp" != *"wasm-pack installed"* ]] || \
        { log_error "FAIL: AC-4 wasm-pack: success message must not appear; got: $output_wp"; ((checks_failed++)); }
    [[ "$output_wp" == *"cargo failed"* ]] || \
        { log_error "FAIL: AC-4 wasm-pack: error message must appear; got: $output_wp"; ((checks_failed++)); }
    [[ "$output_wbc" != *"wasm-bindgen-cli installed"* ]] || \
        { log_error "FAIL: AC-4 wasm-bindgen-cli: success message must not appear; got: $output_wbc"; ((checks_failed++)); }
    [[ "$output_wbc" == *"cargo failed"* ]] || \
        { log_error "FAIL: AC-4 wasm-bindgen-cli: error message must appear; got: $output_wbc"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] cargo install failure: PASSED"
}

# ==============================================================================
# Cycle 4 — AC-5: npm/commitlint/hook_managers failure → no misleading message
# ==============================================================================
test_commitlint_and_hook_managers_failure() {
    local checks_failed=0

    npm() { return 1; }
    export -f npm

    local output_cl output_hm
    output_cl=$(install_commitlint 2>&1) || true
    output_hm=$(install_hook_managers 2>&1) || true

    unset -f npm

    [[ "$output_cl" != *"commitlint dependencies installed"* ]] || \
        { log_error "FAIL: AC-5 commitlint: success message must not appear; got: $output_cl"; ((checks_failed++)); }
    [[ "$output_cl" == *"commitlint installation via npm failed"* ]] || \
        { log_error "FAIL: AC-5 commitlint: error message must appear; got: $output_cl"; ((checks_failed++)); }
    [[ "$output_hm" != *"Global hook managers installation attempted"* ]] || \
        { log_error "FAIL: AC-5 hook_managers: misleading 'attempted' message must not appear; got: $output_hm"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] commitlint and hook_managers npm failure: PASSED"
}

# ==============================================================================
# Cycle 5 — AC-6: opentofu dispatcher || trap → no false "No version" warn
# ==============================================================================
test_dispatcher_opentofu_failure_no_false_warn() {
    local checks_failed=0

    install_binary_from_github() { return 1; }

    local output
    output=$(install_tool "opentofu" 2>&1) || true

    unset -f install_binary_from_github

    [[ "$output" != *"No version for 'opentofu' in SSoT"* ]] || \
        { log_error "FAIL: AC-6: false 'No version' warn must not appear on installer failure; got: $output"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] dispatcher opentofu failure no false warn: PASSED"
}

# ==============================================================================
# Cycle 6 — AC-7 + AC-8: configure_gft_cli PATH/source guidance
# ==============================================================================
test_configure_gft_cli_path_guidance() {
    local checks_failed=0
    local tmp_home; tmp_home=$(mktemp -d)
    local tmp_workspace; tmp_workspace=$(mktemp -d)
    local plt_root="$tmp_workspace/gcs-plt-tools"
    local orig_home="$HOME" orig_ws="${GFT_PROJECTS_HOME:-}" orig_path="$PATH"
    local output_file; output_file=$(mktemp)
    trap 'export HOME="$orig_home" GFT_PROJECTS_HOME="$orig_ws" PATH="$orig_path"; rm -rf "$tmp_home" "$tmp_workspace" "$output_file"' RETURN

    mkdir -p "$plt_root"
    cat > "$plt_root/onboard.sh" <<'MOCK'
#!/usr/bin/env bash
mkdir -p "$HOME/.local/bin"
printf '#!/usr/bin/env bash\n[[ "${1:-}" == "version" ]] && echo "2.0.0" && exit 0\n' \
    > "$HOME/.local/bin/gft"
chmod +x "$HOME/.local/bin/gft"
MOCK
    chmod +x "$plt_root/onboard.sh"

    export HOME="$tmp_home"
    export GFT_PROJECTS_HOME="$tmp_workspace"
    export PATH="/usr/bin:/bin"

    # AC-7: bash shell — BASH_VERSION is naturally set in this bash process
    configure_gft_cli >"$output_file" 2>&1 || true
    local output_7; output_7=$(<"$output_file")
    [[ "$output_7" == *"source"*".bashrc"* ]] || \
        { log_error "FAIL: AC-7: source .bashrc guidance not found; got: $output_7"; ((checks_failed++)); }

    # AC-8: no known shell — GFT_SHELL_PROFILE="" forces the empty-profile branch
    GFT_SHELL_PROFILE="" configure_gft_cli >"$output_file" 2>&1 || true
    local output_8; output_8=$(<"$output_file")
    [[ "$output_8" == *"export PATH"* ]] || \
        { log_error "FAIL: AC-8: export PATH guidance not found; got: $output_8"; ((checks_failed++)); }

    if [[ $checks_failed -ne 0 ]]; then return 1; fi
    log_success "[TEST SUITE] configure_gft_cli PATH guidance: PASSED"
}

main() {
    local failed_suites=0

    test_install_rustup_curl_failure               || ((failed_suites++))
    test_install_rustup_chains_failure             || ((failed_suites++))
    test_cargo_install_failure                     || ((failed_suites++))
    test_commitlint_and_hook_managers_failure      || ((failed_suites++))
    test_dispatcher_opentofu_failure_no_false_warn || ((failed_suites++))
    test_configure_gft_cli_path_guidance           || ((failed_suites++))

    echo "-------------------------------------------"
    if [[ $failed_suites -ne 0 ]]; then
        log_error "🔴 $failed_suites TEST SUITE(S) FAILED." && exit 1
    else
        log_success "✅ ALL TEST SUITES PASSED." && exit 0
    fi
}

main
