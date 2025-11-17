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

create_fake_binary() {
    local dir="$1"
    local name="$2"
    printf '#!/usr/bin/env bash\nexit 0\n' >"${dir}/${name}"
    chmod +x "${dir}/${name}"
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

test_detect_package_manager_priority() {
    log_info "[TEST] Detecting package manager priority order..."
    local temp_dir
    temp_dir=$(mktemp -d)
    local old_path="$PATH"

    create_fake_binary "$temp_dir" apt-get
    create_fake_binary "$temp_dir" dnf
    create_fake_binary "$temp_dir" apk

    PATH="$temp_dir:$old_path"

    unset GFT_PKG_MANAGER GFT_PKG_MANAGER_OVERRIDE
    if ! detect_package_manager; then
        PATH="$old_path"
        rm -rf "$temp_dir"
        log_error "detect_package_manager failed unexpectedly"
        return 1
    fi

    PATH="$old_path"
    rm -rf "$temp_dir"

    if [[ "${GFT_PKG_MANAGER}" != "apt" ]]; then
        log_error "Expected 'apt' to be selected, but got '${GFT_PKG_MANAGER:-unset}'"
        return 1
    fi

    unset GFT_PKG_MANAGER
    log_success "detect_package_manager selected the first available manager."
}

test_detect_package_manager_override() {
    log_info "[TEST] Detecting package manager override handling..."
    unset GFT_PKG_MANAGER
    GFT_PKG_MANAGER_OVERRIDE="winget"

    if ! detect_package_manager; then
        log_error "detect_package_manager did not honor override"
        return 1
    fi

    if [[ "${GFT_PKG_MANAGER}" != "winget" ]]; then
        log_error "Expected override to set manager to 'winget', but got '${GFT_PKG_MANAGER:-unset}'"
        return 1
    fi

    unset GFT_PKG_MANAGER
    unset GFT_PKG_MANAGER_OVERRIDE
    log_success "detect_package_manager respected the override variable."
}

test_detect_package_manager_failure() {
    log_info "[TEST] Detecting failure when no package managers exist..."
    local old_path="$PATH"
    PATH="/nonexistent"

    unset GFT_PKG_MANAGER GFT_PKG_MANAGER_OVERRIDE

    set +e
    detect_package_manager
    local status=$?
    set -e

    PATH="$old_path"

    if [[ $status -eq 0 ]]; then
        log_error "detect_package_manager should have failed when no managers exist"
        return 1
    fi

    unset GFT_PKG_MANAGER
    log_success "detect_package_manager correctly failed without package managers."
}

main() {
    test_install_with_package_manager_dispatch
    test_detect_package_manager_priority
    test_detect_package_manager_override
    test_detect_package_manager_failure
}

main "$@"
