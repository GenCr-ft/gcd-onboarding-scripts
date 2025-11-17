#!/usr/bin/env bash
set -euo pipefail

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)

export TEST_ENV=true

source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
source "${PROJECT_ROOT}/includes/01_helpers.sh"

CAPTURED_COMMANDS=()

run_command_with_logging() {
    CAPTURED_COMMANDS+=("$*")
    return 0
}

reset_capture() {
    CAPTURED_COMMANDS=()
}

assert_commands_match() {
    local expected=("$@")
    if [[ ${#CAPTURED_COMMANDS[@]} -ne ${#expected[@]} ]]; then
        log_error "Command count mismatch. Expected ${#expected[@]}, got ${#CAPTURED_COMMANDS[@]}"
        printf 'Captured commands:\n%s\n' "${CAPTURED_COMMANDS[*]}"
        return 1
    fi

    local idx
    for idx in "${!expected[@]}"; do
        if [[ "${CAPTURED_COMMANDS[$idx]}" != "${expected[$idx]}" ]]; then
            log_error "Mismatch at position $idx. Expected '${expected[$idx]}', got '${CAPTURED_COMMANDS[$idx]}'"
            return 1
        fi
    done
    return 0
}

run_case() {
    local package_manager="$1"; shift
    local package_name="demo-cli"
    reset_capture
    GFT_PKG_MANAGER_OVERRIDE="$package_manager" \
        install_with_package_manager "$package_name" "demo-binary"
    assert_commands_match "$@"
}

test_install_with_package_manager_dispatch() {
    log_info "[TEST] Validating package manager dispatch..."

    run_case brew \
        "brew install demo-cli"

    run_case apt \
        "sudo apt-get update" \
        "sudo apt-get install -y demo-cli"

    run_case dnf \
        "sudo dnf install -y demo-cli"

    run_case apk \
        "sudo apk add --no-cache demo-cli"

    run_case pacman \
        "sudo pacman -Sy --noconfirm demo-cli"

    run_case winget \
        "winget install --exact --id demo-cli --silent"

    log_success "Package manager dispatch logic validated."
}

main() {
    test_install_with_package_manager_dispatch
}

main "$@"
