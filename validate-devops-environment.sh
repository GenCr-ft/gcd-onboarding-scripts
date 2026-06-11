#!/bin/bash
# Script: validate-devops-environment.sh
# Description: Validates the presence and critical configuration of essential DevOps tools
#              specifically for PROJ-103 and ongoing GenCr@ft studio development.
#              Optimized for WSL/Ubuntu.
# Version: 1.5.0 (Added pre-commit check, updated doc paths for ADR-001)
# Author: Camille (Gem AB - Automation Specialist)
# SSoT: gcd-onboarding-scripts/validations-scripts/validate-gft-devops-environment.sh
# Based on previous version: 1.4

# --- Configuration - Minimum Expected Versions (sync with GenCr@ft SSoT) ---
EXPECTED_OPENTOFU_VERSION_MAJOR=1
EXPECTED_OPENTOFU_VERSION_MINOR=6
EXPECTED_PYTHON_VERSION_MAJOR=3
EXPECTED_PYTHON_VERSION_MINOR=8 # pre-commit often needs a reasonably modern Python for all its hooks
EXPECTED_PIP_VERSION_MAJOR=20   # Example, ensure pip is functional and can install pre-commit
EXPECTED_GIT_VERSION_MAJOR=2
EXPECTED_GH_VERSION_MAJOR=2
EXPECTED_PRECOMMIT_VERSION_MAJOR=2 # pre-commit version, e.g. v2.x.x or v3.x.x
ORGANIZATION="GenCr-ft"

# --- Output Colors ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Utility Functions ---
FAIL_COUNT=0
WARN_COUNT=0

print_header() {
    echo -e "\n${BLUE}--- Section $1: $2 ---${NC}"
} #

print_status() {
    local prefix
    case "$2" in
        OK)   prefix="[${GREEN}OK${NC}]     ";;
        FAIL) prefix="[${RED}FAIL${NC}]   "; ((FAIL_COUNT++));;
        WARN) prefix="[${YELLOW}WARN${NC}]   "; ((WARN_COUNT++));;
        INFO) prefix="[${CYAN}INFO${NC}]   ";;
        *)    prefix="[????]   ";;
    esac
    echo -e "$prefix$1"
} #

check_command_exists() {
    local cmd="$1"
    local desc="$2"
    local ref="$3"
    local install_suggestion_ubuntu="$4"
    local install_suggestion_other="$5"
    local msg_base="$desc ($cmd)"
    local msg_detail

    if command -v "$cmd" &> /dev/null; then
        msg_detail="Found: $(command -v "$cmd")"
        print_status "$msg_base: $msg_detail" "OK"
        return 0
    else
        msg_detail="Not found."
        if [ -n "$ref" ]; then
            msg_detail="$msg_detail (Standard reference: $ref)"
        fi
        print_status "$msg_base: $msg_detail" "FAIL"

        if [ -n "$install_suggestion_ubuntu" ]; then
            print_status "  Installation suggestion (Ubuntu/WSL): $install_suggestion_ubuntu" "INFO"
            if [[ "$install_suggestion_ubuntu" == *"sudo"* || "$install_suggestion_ubuntu" == *"apt"* || "$install_suggestion_ubuntu" == *"gem"* ]]; then
                print_status "    (Note: Installation may require 'sudo' privileges.)" "INFO"
            fi
        fi
        if [ -n "$install_suggestion_other" ]; then
            print_status "  Installation suggestion (Other OS, e.g. macOS): $install_suggestion_other" "INFO"
        fi
        if [ -z "$install_suggestion_ubuntu" ] && [ -z "$install_suggestion_other" ]; then
             print_status "  No automatic installation suggestion available. Please install it manually." "INFO"
        fi
        return 1
    fi
} #

check_version() {
    local version_cmd="$1"
    local tool_name="$2"
    local expected_major="$3"
    local expected_minor="$4"
    local version_regex_extract="$5"
    local version_cmd_output
    local current_version current_major current_minor

    # Check if command exists before trying to get version
    if ! command -v "${version_cmd%% *}" &> /dev/null; then # Takes the first word of version_cmd as the command
      return 1
    fi

    print_status "Checking version of $tool_name..." "INFO"
    version_cmd_output=$($version_cmd 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ];then
        print_status "$tool_name: Unable to retrieve version. Command '$version_cmd' failed." "FAIL"
        return 1
    fi

    if [ -n "$version_regex_extract" ]; then
        current_version=$(echo "$version_cmd_output" | grep -oP "$version_regex_extract" | head -n 1)
    else
        current_version=$(echo "$version_cmd_output" | grep -oP '([0-9]+\.[0-9]+(\.[0-9]+)?)' | head -n 1)
    fi

    if [ -z "$current_version" ]; then
        print_status "$tool_name: Unable to extract numeric version from output: \n$version_cmd_output" "WARN"
        return 1
    fi

    current_major=$(echo "$current_version" | cut -d. -f1)
    current_minor=$(echo "$current_version" | cut -d. -f2)

    if ! [[ "$current_major" =~ ^[0-9]+$ ]] || ! [[ "$current_minor" =~ ^[0-9]+$ ]]; then
        print_status "$tool_name: Extracted version '$current_version' is not in the expected numeric format X.Y(.Z)." "FAIL"
        return 1
    fi

    if [ "$current_major" -gt "$expected_major" ] || \
       ( [ "$current_major" -eq "$expected_major" ] && [ "$current_minor" -ge "$expected_minor" ] ); then
        print_status "$tool_name: Version $current_version (expected >= $expected_major.$expected_minor). Compliant." "OK"
        return 0
    else
        print_status "$tool_name: Version $current_version (expected >= $expected_major.$expected_minor). Non-compliant." "FAIL"
        return 1
    fi
} #

# --- Checks Begin ---
echo "======================================================================"
echo "GenCr@ft DevOps Environment Validation for PROJ-103"
echo "Target system: WSL / Ubuntu Linux"
echo "Date: $(date)"
echo "This script checks the essential tools and configurations."
echo "Manual verification of extended GitHub permissions is required."
echo "======================================================================"

# 1. Git (Version Control)
print_header "1" "Git (Version Control)"
if check_command_exists "git" "Git" "gcs-core-governance/tooling/TOOL_00X_Git_Usage_Standard.md" "sudo apt update && sudo apt install git -y"; then
    check_version "git --version" "Git" "$EXPECTED_GIT_VERSION_MAJOR" 0 'git version \K([0-9]+\.[0-9]+(\.[0-9]+)?)'

    GIT_USER_NAME=$(git config --global user.name)
    GIT_USER_EMAIL=$(git config --global user.email)
    if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
        print_status "Global Git configuration (user.name, user.email): Missing. Recommended." "WARN"
        print_status "  Run: git config --global user.name \"Your Name\"" "INFO"
        print_status "  Run: git config --global user.email \"your.email@example.com\"" "INFO"
    else
        print_status "Global Git configuration (user.name, user.email): Present ($GIT_USER_NAME <$GIT_USER_EMAIL>)." "OK"
    fi
fi

# 2. GitHub CLI (gh)
print_header "2" "GitHub CLI (gh)"
if check_command_exists "gh" "GitHub CLI" "gcs-core-governance/tooling/TOOL_005_GitHub_CLI_Standard.md" "See https://github.com/cli/cli#installation (Linux/Debian/Ubuntu instructions)"; then
    check_version "gh --version" "GitHub CLI" "$EXPECTED_GH_VERSION_MAJOR" 0 'gh version \K([0-9]+\.[0-9]+(\.[0-9]+)?)'

    print_status "Checking GitHub CLI authentication (gh auth status)..." "INFO"
    if gh auth status --active > /dev/null 2>&1; then
        GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
        print_status "GitHub CLI (gh): Authenticated to github.com as '$GH_USER'." "OK"
        print_status "  Ensure your token has the necessary permissions for organisation '$ORGANIZATION'." "INFO"
    else
        print_status "GitHub CLI (gh): Not authenticated." "FAIL"
        print_status "  Please run 'gh auth login' and ensure you have the required permissions for organisation '$ORGANIZATION'." "INFO"
    fi
    print_status "  Permissions reference: gcs-core-governance/02-knowledge-base-hub/02-knowledge-base-hub/kb-domain-security/access-control-policy.md" "INFO"

fi

# 3. OpenTofu (tofu) - IaC Tool
print_header "3" "OpenTofu (tofu) - IaC Tool"
if check_command_exists "tofu" "OpenTofu" "gcs-core-governance/iac/IAC_001_OpenTofu_Tooling_Standard.md" "See https://opentofu.org/docs/intro/install (Linux/Debian/Ubuntu)"; then
    check_version "tofu version" "OpenTofu" "$EXPECTED_OPENTOFU_VERSION_MAJOR" "$EXPECTED_OPENTOFU_VERSION_MINOR" 'OpenTofu v\K([0-9]+\.[0-9]+(\.[0-9]+)?)'
fi

# 4. Data Processing Tools (jq)
print_header "4" "Data Processing Tools"
check_command_exists "jq" "jq (JSON processor)" "gcs-core-governance/tooling/TOOL_006_JQ_Usage_Standard.md" "sudo apt install jq -y"

# 5. Linting and Code Quality Tools
print_header "5" "Linting and Quality Tools"
check_command_exists "mdl" "Markdownlint (mdl)" "gcs-core-governance/04-tooling-and-automation-hub/Tools/GCT-TOOL-MDLINT-V1.md" "sudo apt install ruby-full build-essential -y && sudo gem install mdl" "brew install mdl"
check_command_exists "tflint" "TFLint (OpenTofu Linter)" "gcs-core-governance/iac/iac-007-iac-static-analysis-standard.md" "See https://github.com/terraform-linters/tflint#installation"
check_command_exists "tfsec" "TFSec (IaC Security Scanner)" "gcs-core-governance/iac/iac-007-iac-static-analysis-standard.md" "See https://aquasecurity.github.io/tfsec/latest/getting-started/installation/" "brew install tfsec"

if check_command_exists "python3" "Python 3" "" "sudo apt install python3 python3-pip python3-venv -y"; then
    check_version "python3 --version" "Python 3" "$EXPECTED_PYTHON_VERSION_MAJOR" "$EXPECTED_PYTHON_VERSION_MINOR" 'Python \K([0-9]+\.[0-9]+(\.[0-9]+)?)'
    if check_command_exists "pip3" "pip3 (Python Package Installer)"; then
        # Check for pre-commit
        if check_command_exists "pre-commit" "Pre-commit framework" "gcs-core-governance/tooling/TOOL_004_Git_Hooks_Standard.md" "pip3 install pre-commit" "pip3 install pre-commit"; then
             check_version "pre-commit --version" "Pre-commit" "$EXPECTED_PRECOMMIT_VERSION_MAJOR" 0 'pre-commit \K([0-9]+\.[0-9]+(\.[0-9]+)?)'
        fi
    fi
fi

# --- Final Summary ---
echo ""
echo "======================================================================"
echo "DevOps Environment Validation Summary for PROJ-103:"
if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    print_status "All checked tools are PRESENT and COMPLIANT with the base versions." "OK"
elif [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -gt 0 ]; then
    print_status "All essential tools are present, but $WARN_COUNT WARNING(S) remain." "WARN"
    print_status "  This may include missing Git configuration and the need to verify 'gh' permissions." "INFO"
else
    print_status "$FAIL_COUNT critical ERROR(S) detected. $WARN_COUNT WARNING(S) also present." "FAIL"
    print_status "Please fix the ERRORS before running PROJ-103 operations." "FAIL"
fi
echo "Consult the GenCr@ft standards for exact versions and detailed configurations."
echo "  - All standards and protocols are in: gcs-core-governance"
echo "  - Specific DevOps standards are in:   gcs-core-governance"
echo "======================================================================"

exit $FAIL_COUNT
