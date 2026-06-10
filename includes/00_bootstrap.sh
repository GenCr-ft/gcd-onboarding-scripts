#!/usr/bin/env bash
#
# ID: GFT_ONBOARDING_BOOTSTRAP_00
# Title: Onboarding Script - Bootstrap Utilities
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-30
# Version: 1.0.0
#
# Description:
#   Provides early-stage helpers that need to be available before the
#   higher-level helper/installer libraries are sourced. The utilities in
#   this file cover safe command execution, package manager detection, and
#   idempotent package installation routines reused across the suite.

# Executes a command while logging its exact invocation and duration.
run_command_with_logging() {
    local start_ts end_ts duration cmd_display status
    printf -v cmd_display '%q ' "$@"
    log_info "Executing command: ${cmd_display% }"
    start_ts=$(date +%s)
    if "$@"; then
        end_ts=$(date +%s)
        duration=$((end_ts - start_ts))
        log_success "Command succeeded in ${duration}s: ${cmd_display% }"
        return 0
    else
        status=$?
        end_ts=$(date +%s)
        duration=$((end_ts - start_ts))
        log_error "Command failed (exit ${status}) after ${duration}s: ${cmd_display% }"
        return $status
    fi
}

# Detects the first supported package manager available on the host.
detect_package_manager() {
    if [[ -n "${GFT_PKG_MANAGER_OVERRIDE:-}" ]]; then
        GFT_PKG_MANAGER="$GFT_PKG_MANAGER_OVERRIDE"
        return 0
    fi

    if [[ -n "${GFT_PKG_MANAGER:-}" ]]; then
        return 0
    fi

    local manager_candidates=(
        "brew:brew"
        "apt:apt-get"
        "dnf:dnf"
        "apk:apk"
        "pacman:pacman"
        "winget:winget"
    )

    local candidate pair manager binary
    for pair in "${manager_candidates[@]}"; do
        manager=${pair%%:*}
        binary=${pair##*:}
        if command -v "$binary" >/dev/null 2>&1; then
            GFT_PKG_MANAGER="$manager"
            export GFT_PKG_MANAGER
            return 0
        fi
    done

    return 1
}

# Installs a package using the detected package manager while ensuring the
# binary/command is absent before attempting installation (idempotent).
# $1 - Package identifier for the package manager.
# $2 - Optional binary/command name to probe for; defaults to the package
#      identifier when omitted.
install_with_package_manager() {
    local package_name="$1"
    local binary_name="${2:-$package_name}"

    if command -v "$binary_name" >/dev/null 2>&1; then
        log_info "Skipping installation for '${package_name}'; '${binary_name}' already present."
        return 0
    fi

    if ! detect_package_manager; then
        log_error "No supported package manager found. Unable to install '${package_name}'."
        return 1
    fi

    log_info "Installing '${package_name}' using '${GFT_PKG_MANAGER}'."
    case "$GFT_PKG_MANAGER" in
        brew)
            run_command_with_logging brew install "$package_name"
            ;;
        apt)
            run_command_with_logging sudo apt-get update
            run_command_with_logging sudo apt-get install -y "$package_name"
            ;;
        dnf)
            run_command_with_logging sudo dnf install -y "$package_name"
            ;;
        apk)
            run_command_with_logging sudo apk add --no-cache "$package_name"
            ;;
        pacman)
            run_command_with_logging sudo pacman -Sy --noconfirm "$package_name"
            ;;
        winget)
            run_command_with_logging winget install --exact --id "$package_name" --silent
            ;;
        *)
            log_error "Package manager '${GFT_PKG_MANAGER}' is not supported by this script."
            return 1
            ;;
    esac
}
