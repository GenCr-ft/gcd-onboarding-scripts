#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120,SC2015
#
# ID: GFT_ONBOARDING_INSTALLERS_02
# Title: Onboarding Script - SSoT-Driven Tool Installers
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-09
# Last Modified Date: 2025-06-26
# Version: 2.3.0
#
# Description:
#   This script manages the installation of all required development tools. It
#   is driven by the SSoT (.tool-versions-gft) and the role matrix to ensure
#   a standardized environment. It includes specific installers for version
#   managers (nvm, pyenv), binaries from GitHub, and other packages.
#
# Usage:
#   This file is sourced by gft-onboarding.sh.
#
# Dependencies:
#   Functions from 01_helpers.sh.
#   External commands: curl, unzip, tar, sha256sum, sudo, nvm, pyenv.

# --- Helper for OS/Architecture Detection ---
detect_os_arch() {
    if [[ -n "${GFT_OS:-}" ]]; then return; fi
    GFT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch; arch=$(uname -m)
    case "$arch" in
        x86_64) GFT_ARCH="amd64" ;; aarch64|arm64) GFT_ARCH="arm64" ;; *) GFT_ARCH="$arch" ;;
    esac
    export GFT_OS GFT_ARCH
}

# --- Specific SSoT-driven Tool Installers ---

install_node() {
    local version="$1"
    local nvm_version_string
    nvm_version_string=$(echo "$version" | sed 's/-/\//')
    if [[ -z "$nvm_version_string" ]]; then
        log_error "Node.js version not specified — check role tooling matrix in SSoT (GOV-GUIDE-010)."
        return 1
    fi
    log_info "Installing Node.js version '$nvm_version_string' via nvm..."
    # Self-bootstrap nvm if absent (no sudo required — installs into ~/.nvm).
    if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
        log_info "nvm not found — installing nvm automatically..."
        export NVM_DIR="$HOME/.nvm"
        if ! curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
            log_error "Automatic nvm install failed. See https://github.com/nvm-sh/nvm#installing-and-updating"
            return 1
        fi
    fi
    if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
        log_error "nvm still not found after install attempt."
        return 1
    fi
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    . "$HOME/.nvm/nvm.sh"
    if nvm install "$nvm_version_string" && nvm alias default "$nvm_version_string"; then
        log_success "Node.js $version installed and set as default."
    else
        log_error "Node.js '$nvm_version_string' installation via nvm failed."
        return 1
    fi
}

# Loads pyenv into the current shell if present (idempotent).
_load_pyenv() {
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) export PATH="$PYENV_ROOT/bin:$PATH" ;; esac
    command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - 2>/dev/null)" 2>/dev/null || true
}

# True if a system python3 meets the studio floor (>= 3.9).
_system_python_ok() {
    command -v python3 >/dev/null 2>&1 || return 1
    python3 - <<'PY' 2>/dev/null
import sys
raise SystemExit(0 if sys.version_info[:2] >= (3, 9) else 1)
PY
}

# True if we can compile a CLEAN CPython: either passwordless sudo (to add build
# deps) or all key build deps are already present. Prevents pyenv from building a
# Python missing sqlite3/bz2/readline (which build as optional modules with warnings).
_python_can_compile() {
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then return 0; fi
    if command -v dpkg >/dev/null 2>&1; then
        local p
        for p in libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev; do
            dpkg -s "$p" >/dev/null 2>&1 || return 1
        done
        return 0
    fi
    return 1   # unknown platform + no passwordless sudo → prefer the complete system python
}

install_python() {
    local version="$1"
    log_info "Setting up Python (target pinned version '$version' via pyenv)..."

    # 1. Self-bootstrap pyenv if absent (git-based installer — no sudo required).
    if ! command -v pyenv >/dev/null 2>&1 && [ ! -x "$HOME/.pyenv/bin/pyenv" ]; then
        log_info "pyenv not found — installing pyenv automatically..."
        curl -fsSL https://pyenv.run | bash || log_warn "Automatic pyenv install did not complete."
    fi
    _load_pyenv

    # 2. Install the pinned version — but only attempt a compile when we can build a
    #    CLEAN CPython (passwordless sudo to add deps, or deps present). If we can't
    #    and a good system python3 exists, skip straight to the fallback (§3) rather
    #    than build a Python missing sqlite3/bz2/readline.
    if command -v pyenv >/dev/null 2>&1 && { _python_can_compile || ! _system_python_ok; }; then
        if command -v apt-get >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
            log_info "Installing Python build dependencies (apt)..."
            sudo -n apt-get update -qq || true
            sudo -n apt-get install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev \
                libncursesw5-dev xz-utils tk-dev >/dev/null 2>&1 || true
        fi
        pyenv install -s "$version" 2>/dev/null || true
        if pyenv versions --bare 2>/dev/null | grep -qx "$version"; then
            pyenv global "$version" 2>/dev/null || true
            log_success "Python $version installed and set as global default via pyenv."
            return 0
        fi
    fi

    # 3. Graceful fallback: don't block onboarding if a compatible system python3 exists.
    if _system_python_ok; then
        local sysver
        sysver=$(python3 -c 'import sys;print("%d.%d.%d"%sys.version_info[:3])' 2>/dev/null)
        log_warn "Could not install pinned Python $version via pyenv (needs build deps / sudo)."
        log_warn "Using system python3 $sysver, which meets the >= 3.9 requirement. Onboarding continues."
        log_info "  To pin exactly later:  pyenv install $version && pyenv global $version"
        return 0
    fi

    log_error "Python $version could not be installed via pyenv and no python3 >= 3.9 was found."
    log_info "  Install pyenv build deps or a system python3 >= 3.9, then re-run."
    return 1
}

install_binary_from_github() {
    local tool_name="$1"; local version="$2"; local repo_url="$3"; local bin_name_in_zip="$4"
    log_info "Installing $tool_name version '$version' from GitHub releases..."
    if command -v "$bin_name_in_zip" &>/dev/null && [[ "$(eval "$bin_name_in_zip --version")" == *"$version"* ]]; then log_info "$tool_name $version is already installed." && return 0; fi
    local install_dir="$HOME/.local/bin"; mkdir -p "$install_dir"; local file_prefix="${tool_name}_${version}"
    if [[ "$tool_name" == "gft-cli" ]]; then file_prefix="gft-cli-v${version}"; fi
    local release_file="${file_prefix}_${GFT_OS}_${GFT_ARCH}.tar.gz"
    local checksum_file="checksums.txt"
    local download_url="https://github.com/${repo_url}/releases/download/v${version}"
    if [[ "$tool_name" == "gft-cli" ]]; then download_url="https://github.com/${repo_url}/releases/download/gft-cli-v${version}"; fi
    (
        cd /tmp || exit 1
        log_info "Downloading $tool_name binary and checksums..." && curl -sSL -O "${download_url}/${release_file}" && curl -sSL -O "${download_url}/${checksum_file}"
        log_info "Verifying checksum..."
        if ! grep "$release_file" "$checksum_file" | sha256sum --check --status; then
            log_error "Checksum verification failed for $tool_name." && rm -f "$release_file" "$checksum_file" && exit 1
        fi
        log_info "Installing $tool_name..." && tar -xzf "$release_file" && mv "$bin_name_in_zip" "${install_dir}/" && chmod +x "${install_dir}/${bin_name_in_zip}"
        rm -f "$release_file" "$checksum_file"
    ) || return 1
    log_success "$tool_name $version installed to ${install_dir}/${bin_name_in_zip}"
}

install_aws_cli() {
    log_info "Installing AWS CLI v2..."
    if command -v aws &>/dev/null && [[ "$(aws --version 2>&1)" == *"aws-cli/2"* ]]; then log_info "AWS CLI v2 is already installed." && return 0; fi
    detect_os_arch
    local aws_arch="x86_64"
    if [[ "$GFT_ARCH" == "arm64" ]]; then aws_arch="aarch64"; fi
    (
        cd /tmp || exit 1
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o "awscliv2.zip" && unzip -oq awscliv2.zip && sudo ./aws/install
        rm -rf aws awscliv2.zip
    ) || return 1
    log_success "AWS CLI v2 ($aws_arch) installed."
}

install_hook_managers() {
    log_info "Installing global hook managers (pre-commit, lint-staged)..."
    local any_failed=false
    if command -v npm &>/dev/null; then
        if npm install -g lint-staged; then
            log_success "lint-staged installed."
        else
            log_warn "lint-staged installation via npm failed. Pre-commit hooks may not work."
            any_failed=true
        fi
    else
        log_warn "npm not found, skipping lint-staged."
    fi
    if command -v pip3 &>/dev/null; then
        if pip3 install --user pre-commit; then
            log_success "pre-commit installed."
        else
            log_warn "pre-commit installation via pip3 failed. Git hooks may not work."
            any_failed=true
        fi
    else
        log_warn "pip3 not found, skipping pre-commit."
    fi
    if $any_failed; then
        log_warn "One or more hook managers failed to install (see above). Git hooks may not function correctly."
    else
        log_info "Hook manager installation complete."
    fi
}

verify_docker() {
    log_info "Verifying Docker installation..."
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log_success "Docker is installed and the daemon is running."
    else
        log_error "Docker is not installed or the Docker daemon is not running. Please install Docker Desktop and start it."
    fi
}

install_commitlint() {
    log_info "Installing global npm packages for commitlint..."
    if ! command -v npm &>/dev/null; then log_error "npm is required to install commitlint." && return 1; fi
    if npm install -g @commitlint/cli @commitlint/config-conventional; then
        log_success "commitlint dependencies installed."
    else
        log_error "commitlint installation via npm failed. Check npm output above."
        return 1
    fi
}

install_prettier() {
    log_info "Installing prettier (global npm package)..."
    # npm comes from nvm's node (installed earlier); source nvm if not yet on PATH.
    if ! command -v npm >/dev/null 2>&1 && [ -s "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        . "$HOME/.nvm/nvm.sh"
    fi
    if ! command -v npm >/dev/null 2>&1; then
        log_warn "npm not available yet — skipping prettier (formatter, non-blocking)."
        return 0
    fi
    if npm install -g prettier; then
        log_success "prettier installed."
    else
        log_warn "prettier installation via npm failed (non-blocking)."
    fi
    return 0
}

install_rustup() {
    log_info "Installing Rust toolchain via rustup..."
    if command -v rustup &>/dev/null; then
        log_info "rustup is already installed. Running rustup update..."
        if rustup update stable && rustup target add wasm32-unknown-unknown; then
            log_success "Rust toolchain updated."
        else
            log_error "Rust toolchain update failed. Check rustup output above."
            return 1
        fi
        return 0
    fi
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable; then
        log_error "rustup installer failed. Install manually: https://rustup.rs"
        log_info "  After installation, restart your shell and re-run this script."
        return 1
    fi
    # shellcheck source=/dev/null
    if [ ! -f "$HOME/.cargo/env" ]; then
        log_warn "\$HOME/.cargo/env not found after rustup install — PATH may not include \$HOME/.cargo/bin."
    else
        . "$HOME/.cargo/env"
    fi
    if rustup target add wasm32-unknown-unknown; then
        log_success "Rust stable toolchain installed with wasm32-unknown-unknown target."
    else
        log_error "rustup installed but 'rustup target add wasm32-unknown-unknown' failed. Check rustup output above."
        return 1
    fi
}

install_wasm_pack() {
    log_info "Installing wasm-pack..."
    if command -v wasm-pack &>/dev/null; then log_info "wasm-pack is already installed." && return 0; fi
    if ! command -v cargo &>/dev/null; then
        log_error "cargo not found. Please ensure the Rust toolchain is installed via 'install_rustup'." && return 1
    fi
    if cargo install wasm-pack --locked; then
        log_success "wasm-pack installed."
    else
        log_error "wasm-pack installation via cargo failed. Check cargo output above."
        return 1
    fi
}

install_wasm_bindgen_cli() {
    log_info "Installing wasm-bindgen-cli..."
    if command -v wasm-bindgen &>/dev/null; then log_info "wasm-bindgen is already installed." && return 0; fi
    if ! command -v cargo &>/dev/null; then
        log_error "cargo not found. Please ensure the Rust toolchain is installed via 'install_rustup'." && return 1
    fi
    if cargo install wasm-bindgen-cli --locked; then
        log_success "wasm-bindgen-cli installed."
    else
        log_error "wasm-bindgen-cli installation via cargo failed. Check cargo output above."
        return 1
    fi
}


# Aligns gft installation with the canonical workspace-managed wrapper contract
# owned by gcs-plt-tools. Pre-clone calls may defer cleanly; post-clone calls
# must delegate to gcs-plt-tools/onboard.sh, which installs/repairs
# ~/.local/bin/gft and ~/.config/gft/config.env for the active workspace.
install_gft_cli() {
    local allow_defer="${1:-true}"
    # gcs-plt-tools (the canonical owner of the global `gft` CLI) is shared
    # tooling — it lives in studio_home() (~/.gft-studio), not the workspace.
    local plt_root; plt_root="$(studio_home)/gcs-plt-tools"
    local onboard_script="${plt_root}/onboard.sh"
    local gft_bin="$HOME/.local/bin/gft"

    if [[ ! -f "$onboard_script" ]]; then
        if [[ "$allow_defer" == "true" ]]; then
            log_warn "gcs-plt-tools onboarding script not found at $onboard_script — deferring gft installation until repositories are cloned."
            return 0
        fi
        log_error "gcs-plt-tools onboarding script not found at $onboard_script — cannot configure gft after clone without the canonical owner repo."
        return 1
    fi

    log_info "Delegating gft installation to $onboard_script ..."
    if ! (cd "$plt_root" && bash "$onboard_script"); then
        log_error "Delegated gft installation via $onboard_script failed."
        return 1
    fi

    export PATH="$HOME/.local/bin:$PATH"

    if "$gft_bin" version &>/dev/null; then
        log_success "gft installed: $("$gft_bin" version)"
    else
        log_error "Delegated gft installation completed, but $gft_bin is still unavailable."
        return 1
    fi
}


# Installs the SSoT compliance linter tool (gcd-ops-scripts) globally using pipx.
install_gft_ops_scripts() {
    local workspace_root="${GFT_PROJECTS_HOME:-$HOME/gft_studio}"
    local ops_scripts_path="${workspace_root}/gcd-ops-scripts"

    if [[ ! -d "$ops_scripts_path" ]]; then
        log_warn "gcd-ops-scripts directory not found at $ops_scripts_path — skipping pipx installation."
        return 0
    fi

    log_info "Installing gft-ops-scripts via pipx..."

    # Ensure pipx is installed
    if ! command -v pipx &>/dev/null; then
        log_info "pipx not found. Attempting to install pipx..."
        local installed=false
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y pipx && installed=true
        elif command -v brew &>/dev/null; then
            brew install pipx && installed=true
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y pipx && installed=true
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm python-pipx && installed=true
        fi

        if ! $installed; then
            log_warn "Package manager installation failed or not found. Falling back to pip with --break-system-packages..."
            python3 -m pip install --user pipx --break-system-packages || python3 -m pip install --user pipx
        fi
        export PATH="${HOME}/.local/bin:${PATH}"
    fi

    if ! command -v pipx &>/dev/null; then
        log_error "pipx is not available in PATH and could not be installed."
        return 1
    fi

    log_info "Running pipx install for gft-ops-scripts..."
    if pipx list | grep -E -q "gft-ops-scripts|gcd-ops-scripts"; then
        log_info "gft-ops-scripts is already installed in pipx. Reinstalling..."
        pipx install --force "$ops_scripts_path"
    else
        pipx install "$ops_scripts_path"
    fi
    log_success "gft-ops-scripts successfully installed via pipx."
}


# --- Main Installation Dispatcher ---
install_tool() {
    local tool_from_matrix="$1"
    log_info "--- Processing tool: $tool_from_matrix ---"
    local version; detect_os_arch
    case "$tool_from_matrix" in
        git) log_info "'git' is a core prerequisite handled at startup." ;;
        github-cli) install_with_package_manager "gh" ;;
        yq) install_with_package_manager "yq" ;;
        shellcheck) install_with_package_manager "shellcheck" ;;
        docker) verify_docker ;;
        commitlint) install_commitlint ;;
        node-lts)
            version=$(get_ssot_tool_version "nodejs")
            if [[ -z "$version" ]]; then
                log_warn "No version for 'nodejs' in SSoT — skipping node-lts installation."
            else
                install_node "$version"
            fi
            ;;
        python)
            version=$(get_ssot_tool_version "python")
            if [[ -z "$version" ]]; then
                log_warn "No version for 'python' in SSoT — skipping python installation."
            else
                install_python "$version"
            fi
            ;;
        opentofu)
            version=$(get_ssot_tool_version "opentofu")
            if [[ -z "$version" ]]; then
                log_warn "No version for 'opentofu' in SSoT — skipping opentofu installation."
            else
                install_binary_from_github "opentofu" "$version" "opentofu/opentofu" "tofu"
            fi
            ;;
        gft-cli) install_gft_cli ;;
        aws-cli) install_aws_cli ;;
        git-hooks-managers) install_hook_managers ;;
        rustup) install_rustup ;;
        wasm-pack) install_wasm_pack ;;
        wasm-bindgen-cli) install_wasm_bindgen_cli ;;
        prettier) install_prettier ;;
        *) log_warn "No SSoT-driven installation logic defined for tool '$tool_from_matrix'." ;;
    esac
}

# --- Main Entry Point for Tool Installation ---
install_tools_for_role() {
    local role_name="$1"
    log_info "Fetching required tool list for role: '$role_name'..."
    local python_helper_script="${SCRIPT_DIR}/includes/get_role_tools.py"
    if [ ! -f "$python_helper_script" ]; then log_error "FATAL: Python helper script not found" && return 1; fi
    mapfile -t required_tools < <(echo "$ROLE_MATRIX_YAML" | python3 "$python_helper_script" "$role_name")
    if [[ ${#required_tools[@]} -eq 0 ]]; then log_info "No specific tools to install for this role." && return; fi
    log_info "The following tools will be installed or verified: ${required_tools[*]}"
    if [[ -z "${TEST_ENV:-}" ]]; then if ! confirm_action "Proceed with tool installation?"; then log_warn "Skipped by user." && return; fi; fi
    for tool in "${required_tools[@]}"; do install_tool "$tool"; done
    log_success "Tool installation phase complete."
}

performance_and_caching() {
    if ! command -v docker &> /dev/null; then
        log_warn "Docker command not found. Skipping image pre-pull stage."
        return
    fi

    if [ -z "${GFT_SSOT_PATH:-}" ]; then
        log_warn "GFT_SSOT_PATH is undefined; cannot load Docker image manifest."
        return
    fi

    local docker_manifest="${GFT_SSOT_PATH}/tooling/ssot/.docker-images-gft"
    if [ ! -f "$docker_manifest" ]; then
        log_warn "Docker manifest '$docker_manifest' not found."
        return
    fi

    mapfile -t docker_images < <(grep -vE '^\s*(#|$)' "$docker_manifest" || true)
    if [[ ${#docker_images[@]} -eq 0 ]]; then
        log_info "No Docker images listed for pre-pull caching."
        return
    fi

    if [[ -z "${TEST_ENV:-}" ]]; then
        if ! confirm_action "Pre-pull ${#docker_images[@]} Docker images for performance caching?"; then
            log_warn "Docker image pre-pull skipped by user."
            return
        fi
    fi

    log_info "Pre-pulling ${#docker_images[@]} Docker images defined in SSoT..."
    local failures=0
    for image in "${docker_images[@]}"; do
        log_info "Caching image: $image"
        if docker pull "$image"; then
            log_success "Image '$image' cached locally."
        else
            log_error "Failed to pull image '$image'."
            failures=1
        fi
    done

    if [[ $failures -eq 0 ]]; then
        log_success "All Docker images cached successfully."
    else
        log_warn "One or more Docker images failed to pull. Review the errors above."
    fi
}
