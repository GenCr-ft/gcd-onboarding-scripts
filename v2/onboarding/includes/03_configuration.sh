#!/usr/bin/env bash

# ==============================================================================
# Onboarding Script - Part 3: Environment Configuration Functions
# ==============================================================================

# Configures global Git user name and email
configure_git() {
    log_info "Configuring Git..."

    local current_name
    current_name=$(git config --global user.name || echo "")
    if [[ -z "$current_name" ]]; then
        read -r -p "Enter your full name for Git commits: " user_name
        git config --global user.name "$user_name"
    else
        log_info "Git user.name is already set to: $current_name"
    fi

    local current_email
    current_email=$(git config --global user.email || echo "")
    if [[ -z "$current_email" ]]; then
        read -r -p "Enter your email for Git commits: " user_email
        git config --global user.email "$user_email"
    else
        log_info "Git user.email is already set to: $current_email"
    fi

    # Set other global configs from SSoT
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    log_success "Git has been configured."
}

# Sets up an SSH key and adds it to GitHub
setup_ssh_key() {
    log_info "Checking for SSH key..."
    local ssh_key_path="$HOME/.ssh/id_ed25519"
    if [ ! -f "$ssh_key_path" ]; then
        log_warn "No SSH key found. Let's create one."
        local git_email
        git_email=$(git config --global user.email)
        ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key_path" -N ""
        log_success "New SSH key created at $ssh_key_path"
    else
        log_info "Existing SSH key found."
    fi

    if confirm_action "Add this SSH key to your GitHub account automatically?"; then
        if ! command -v gh &> /dev/null; then
            log_error "GitHub CLI 'gh' not found. Cannot add SSH key automatically."
            return 1
        fi
        log_info "Adding SSH key to GitHub..."
        gh ssh-key add "$ssh_key_path.pub" --title "Onboarding-$(hostname)"
        log_success "SSH key added to GitHub account."
    fi
}

# Sets up the global commit-msg hook to enforce Conventional Commits
setup_global_git_hooks() {
    log_info "Setting up global Git hooks for Conventional Commits..."
    local hooks_dir="$HOME/.gft-git-hooks"
    mkdir -p "$hooks_dir"

    local hook_file="$hooks_dir/commit-msg"

    # Create the commit-msg hook script
    cat > "$hook_file" << EOF
#!/bin/sh
# This hook is managed by the GenCr@t onboarding script.
# It enforces Conventional Commits standard using commitlint.
npx commitlint --edit "\$1"
EOF

    chmod +x "$hook_file"
    git config --global core.hooksPath "$hooks_dir"
    log_success "Global commit-msg hook configured."
}

# Installs all VS Code extensions required for a given role
install_vscode_extensions_for_role() {
    local role_name="$1"
    if ! command -v code &> /dev/null; then
        log_warn "VS Code 'code' command not found in PATH. Skipping extension installation."
        return
    fi

    log_info "Fetching required VS Code extensions for role: $role_name"
    local required_extensions
    mapfile -t required_extensions < <(echo "$ROLE_MATRIX_YAML" | yq -r "
        (.roles[] | select(.name == \"$role_name\") | .vscode_extensions[]?),
        (.roles[] | select(.name == \"$role_name\") | .inherits | select(. != null) | . as \$base_role | .roles[] | select(.name == \$base_role) | .vscode_extensions[]?)
    " | sort -u)

    if [[ ${#required_extensions[@]} -eq 0 ]]; then log_info "No specific extensions for this role."; return; fi

    log_info "Installing ${#required_extensions[@]} VS Code extensions..."
    for ext_id in "${required_extensions[@]}"; do
        if code --list-extensions | grep -qiw "$ext_id"; then
            log_info "Extension '$ext_id' is already installed."
        else
            log_info "Installing extension: $ext_id"
            code --install-extension "$ext_id"
        fi
    done
    log_success "VS Code extension setup complete."
}

# Clones all repositories required for a given role
clone_repositories_for_role() {
    local role_name="$1"
    log_info "Cloning required repositories for role: $role_name"

    local gft_workspace="$HOME/gft_studio" # Central workspace directory
    mkdir -p "$gft_workspace"

    local required_repos
    mapfile -t required_repos < <(echo "$ROLE_MATRIX_YAML" | yq -r "
        (.roles[] | select(.name == \"$role_name\") | .repositories[]?),
        (.roles[] | select(.name == \"$role_name\") | .inherits | select(. != null) | . as \$base_role | .roles[] | select(.name == \$base_role) | .repositories[]?)
    " | sort -u)

    if [[ ${#required_repos[@]} -eq 0 ]]; then log_info "No specific repositories to clone for this role."; return; fi

    if confirm_action "Clone ${#required_repos[@]} repositories into '$gft_workspace'?"; then
        for repo_name in "${required_repos[@]}"; do
            if [ -d "$gft_workspace/$repo_name" ]; then
                log_info "Repository '$repo_name' already exists. Skipping."
            else
                log_info "Cloning GenCr-ft/$repo_name..."
                gh repo clone "GenCr-ft/$repo_name" "$gft_workspace/$repo_name"
            fi
        done
        log_success "Repository cloning complete."
    else
        log_warn "Repository cloning skipped by user."
    fi
}
