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
# --- Test Runner ---
# ==============================================================================
main() {
    local failed_suites=0

    test_install_rustup_curl_failure               || ((failed_suites++))

    echo "-------------------------------------------"
    if [[ $failed_suites -ne 0 ]]; then
        log_error "🔴 $failed_suites TEST SUITE(S) FAILED." && exit 1
    else
        log_success "✅ ALL TEST SUITES PASSED." && exit 0
    fi
}

main
