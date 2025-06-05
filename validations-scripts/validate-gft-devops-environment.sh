#!/bin/bash
# Script: validate_gft_devops_environment.sh
# Description: Validates the presence and critical configuration of essential DevOps tools
#              specifically for PROJ-103 and ongoing GenCr@ft studio development.
#              Optimized for WSL/Ubuntu.
# Version: 1.5.0 (Added pre-commit check, updated doc paths for ADR-001)
# Author: Camille (Gem AB - Automation Specialist)
# SSoT: gcd-onboarding-scripts/validations-scripts/validate_gft_devops_environment.sh
# Based on previous version: 1.4

# --- Configuration - Versions Minimales Attendues (À synchroniser avec les SSoT Gencraft) ---
EXPECTED_OPENTOFU_VERSION_MAJOR=1
EXPECTED_OPENTOFU_VERSION_MINOR=6
EXPECTED_PYTHON_VERSION_MAJOR=3
EXPECTED_PYTHON_VERSION_MINOR=8 # pre-commit often needs a reasonably modern Python for all its hooks
EXPECTED_PIP_VERSION_MAJOR=20   # Example, ensure pip is functional and can install pre-commit
EXPECTED_GIT_VERSION_MAJOR=2
EXPECTED_GH_VERSION_MAJOR=2 
EXPECTED_PRECOMMIT_VERSION_MAJOR=2 # Version de pre-commit, par exemple v2.x.x ou v3.x.x
ORGANIZATION="GenCr-ft"

# --- Couleurs pour l'output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Fonctions Utilitaires ---
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
        msg_detail="Présent: $(command -v "$cmd")"
        print_status "$msg_base: $msg_detail" "OK"
        return 0
    else
        msg_detail="Non trouvé."
        if [ -n "$ref" ]; then
            msg_detail="$msg_detail (Référence standard: $ref)"
        fi
        print_status "$msg_base: $msg_detail" "FAIL"

        if [ -n "$install_suggestion_ubuntu" ]; then
            print_status "  Suggestion d'installation (Ubuntu/WSL): $install_suggestion_ubuntu" "INFO"
            if [[ "$install_suggestion_ubuntu" == *"sudo"* || "$install_suggestion_ubuntu" == *"apt"* || "$install_suggestion_ubuntu" == *"gem"* ]]; then # Added gem for mdl
                print_status "    (Note: L'installation peut nécessiter des droits 'sudo'.)" "INFO"
            fi
        fi
        if [ -n "$install_suggestion_other" ]; then
            print_status "  Suggestion d'installation (Autre OS, ex: macOS): $install_suggestion_other" "INFO"
        fi
        if [ -z "$install_suggestion_ubuntu" ] && [ -z "$install_suggestion_other" ]; then
             print_status "  Aucune suggestion d'installation automatique disponible. Veuillez l'installer manuellement." "INFO"
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
      # print_status "$tool_name: Commande de base non trouvée, impossible de vérifier la version." "FAIL" # Already handled by check_command_exists
      return 1
    fi

    print_status "Vérification de la version de $tool_name..." "INFO"
    version_cmd_output=$($version_cmd 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ];then
        print_status "$tool_name: Impossible de récupérer la version. Commande '$version_cmd' échouée." "FAIL"
        return 1
    fi

    if [ -n "$version_regex_extract" ]; then
        current_version=$(echo "$version_cmd_output" | grep -oP "$version_regex_extract" | head -n 1)
    else
        current_version=$(echo "$version_cmd_output" | grep -oP '([0-9]+\.[0-9]+(\.[0-9]+)?)' | head -n 1)
    fi

    if [ -z "$current_version" ]; then
        print_status "$tool_name: Impossible d'extraire la version numérique à partir de l'output: \n$version_cmd_output" "WARN"
        return 1
    fi

    current_major=$(echo "$current_version" | cut -d. -f1)
    current_minor=$(echo "$current_version" | cut -d. -f2)

    if ! [[ "$current_major" =~ ^[0-9]+$ ]] || ! [[ "$current_minor" =~ ^[0-9]+$ ]]; then
        print_status "$tool_name: Version extraite '$current_version' n'est pas au format numérique attendu X.Y(.Z)." "FAIL"
        return 1
    fi

    if [ "$current_major" -gt "$expected_major" ] || \
       ( [ "$current_major" -eq "$expected_major" ] && [ "$current_minor" -ge "$expected_minor" ] ); then
        print_status "$tool_name: Version $current_version (Attendu >= $expected_major.$expected_minor). Conforme." "OK"
        return 0
    else
        print_status "$tool_name: Version $current_version (Attendu >= $expected_major.$expected_minor). Non conforme." "FAIL"
        return 1
    fi
} #

# --- Début des Vérifications ---
echo "======================================================================"
echo "Validation de l'Environnement DevOps Gencraft pour PROJ-103"
echo "Système Cible: WSL / Ubuntu Linux"
echo "Date: $(date)"
echo "Ce script vérifie les outils et configurations essentiels."
echo "Une vérification manuelle des permissions GitHub étendues est requise."
echo "======================================================================"

# 1. Git (Contrôle de Version)
print_header "1" "Git (Contrôle de Version)"
if check_command_exists "git" "Git" "gcs-devops-standards/tooling/TOOL_00X_Git_Usage_Standard.md" "sudo apt update && sudo apt install git -y"; then # Added -y for non-interactive
    check_version "git --version" "Git" "$EXPECTED_GIT_VERSION_MAJOR" 0 'git version \K([0-9]+\.[0-9]+(\.[0-9]+)?)'

    GIT_USER_NAME=$(git config --global user.name)
    GIT_USER_EMAIL=$(git config --global user.email)
    if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
        print_status "Configuration Git (user.name, user.email) globale: Manquante. Recommandé." "WARN"
        print_status "  Exécutez: git config --global user.name \"Votre Nom\"" "INFO"
        print_status "  Exécutez: git config --global user.email \"votre.email@example.com\"" "INFO"
    else
        print_status "Configuration Git (user.name, user.email) globale: Présente ($GIT_USER_NAME <$GIT_USER_EMAIL>)." "OK"
    fi
fi

# 2. GitHub CLI (gh)
print_header "2" "GitHub CLI (gh)"
if check_command_exists "gh" "GitHub CLI" "gcs-devops-standards/tooling/TOOL_005_GitHub_CLI_Standard.md" "Consultez https://github.com/cli/cli#installation (instructions pour Linux/Debian/Ubuntu)"; then
    check_version "gh --version" "GitHub CLI" "$EXPECTED_GH_VERSION_MAJOR" 0 'gh version \K([0-9]+\.[0-9]+(\.[0-9]+)?)'

    print_status "Vérification de l'authentification GitHub CLI (gh auth status)..." "INFO"
    if gh auth status -h "$ORGANIZATION" > /dev/null 2>&1; then # Check against specific org
        GH_USER=$(gh auth status -h github.com --show-token 2>/dev/null | grep "Logged in to github.com as" | sed 's/.*Logged in to github.com as \([^ ]*\) .*/\1/')
        print_status "GitHub CLI (gh): Authentifié sur github.com en tant que '$GH_USER' et accès à '$ORGANIZATION' confirmé." "OK"
    elif gh auth status > /dev/null 2>&1; then
        GH_USER=$(gh auth status -h github.com --show-token 2>/dev/null | grep "Logged in to github.com as" | sed 's/.*Logged in to github.com as \([^ ]*\) .*/\1/')
        print_status "GitHub CLI (gh): Authentifié sur github.com en tant que '$GH_USER', mais l'accès à l'organisation '$ORGANIZATION' n'a pas pu être confirmé directement par 'gh auth status -h $ORGANIZATION'." "WARN"
        print_status "  Assurez-vous que votre token a les droits nécessaires pour l'organisation '$ORGANIZATION'." "INFO"
    else
        print_status "GitHub CLI (gh): Non authentifié." "FAIL"
        print_status "  Veuillez exécuter 'gh auth login' et vous assurer d'avoir les permissions nécessaires pour l'organisation '$ORGANIZATION'." "INFO"
    fi
    # Removed detailed permissions check, as it's too complex for this script and better handled by context.
    # The original detailed permission check note remains valid for manual verification by the user.
    print_status "  Référence pour les permissions: gcs-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Security/Access-Control-Policy.md" "INFO"

fi

# 3. OpenTofu (tofu)
print_header "3" "OpenTofu (tofu) - IaC Tool"
if check_command_exists "tofu" "OpenTofu" "gcs-devops-standards/iac/IAC_001_OpenTofu_Tooling_Standard.md" "Consultez https://opentofu.org/docs/intro/install (Linux/Debian/Ubuntu)"; then
    check_version "tofu version" "OpenTofu" "$EXPECTED_OPENTOFU_VERSION_MAJOR" "$EXPECTED_OPENTOFU_VERSION_MINOR" 'OpenTofu v\K([0-9]+\.[0-9]+(\.[0-9]+)?)'
fi

# 4. Outils de Traitement de Données (jq)
print_header "4" "Outils de Traitement de Données"
check_command_exists "jq" "jq (JSON processor)" "gcs-devops-standards/tooling/TOOL_006_JQ_Usage_Standard.md" "sudo apt install jq -y"

# 5. Outils de Linting et Qualité de Code
print_header "5" "Outils de Linting et Qualité"
check_command_exists "mdl" "Markdownlint (mdl)" "gcs-studio-handbook/04-Tooling-And-Automation-Hub/Tools/GCT-TOOL-MDLINT-V1.md" "sudo apt install ruby-full build-essential -y && sudo gem install mdl" "brew install mdl"
check_command_exists "tflint" "TFLint (OpenTofu Linter)" "gcs-devops-standards/iac/IAC_007_IaC_Static_Analysis_Standard.md" "Consultez https://github.com/terraform-linters/tflint#installation"
check_command_exists "tfsec" "TFSec (IaC Security Scanner)" "gcs-devops-standards/iac/IAC_007_IaC_Static_Analysis_Standard.md" "Consultez https://aquasecurity.github.io/tfsec/latest/getting-started/installation/" "brew install tfsec"
# check_command_exists "checkov" "Checkov (Alternative IaC Scanner)" "" "pip3 install checkov" "pip3 install checkov"

if check_command_exists "python3" "Python 3" "" "sudo apt install python3 python3-pip python3-venv -y"; then
    check_version "python3 --version" "Python 3" "$EXPECTED_PYTHON_VERSION_MAJOR" "$EXPECTED_PYTHON_VERSION_MINOR" 'Python \K([0-9]+\.[0-9]+(\.[0-9]+)?)'
    if check_command_exists "pip3" "pip3 (Python Package Installer)"; then 
        # Check for pre-commit
        if check_command_exists "pre-commit" "Pre-commit framework" "gcs-devops-standards/tooling/TOOL_004_Git_Hooks_Standard.md" "pip3 install pre-commit" "pip3 install pre-commit"; then
             check_version "pre-commit --version" "Pre-commit" "$EXPECTED_PRECOMMIT_VERSION_MAJOR" 0 'pre-commit \K([0-9]+\.[0-9]+(\.[0-9]+)?)'
        fi
    fi
fi

# --- Résumé Final ---
echo ""
echo "======================================================================"
echo "Résumé de la Validation de l'Environnement DevOps pour PROJ-103 :"
if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    print_status "Tous les outils vérifiés sont PRÉSENTS et CONFORMES aux versions de base." "OK"
elif [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -gt 0 ]; then
    print_status "Tous les outils essentiels sont présents, mais $WARN_COUNT AVERTISSEMENT(S) subsiste(nt)." "WARN"
    print_status "  Cela inclut potentiellement la configuration Git et la nécessité de vérifier les permissions 'gh'." "INFO"
else
    print_status "$FAIL_COUNT ERREUR(S) critique(s) détectée(s). $WARN_COUNT AVERTISSEMENT(S) également présent(s)." "FAIL"
    print_status "Veuillez corriger les ERREURS pour pouvoir exécuter les opérations de PROJ-103." "FAIL"
fi
echo "Consultez les standards Gencraft pour les versions exactes et les configurations détaillées."
echo "  - Tous les standards et protocoles sont dans : gcs-studio-handbook"
echo "  - Les standards DevOps spécifiques sont dans : gcs-devops-standards"
echo "======================================================================"

exit $FAIL_COUNT
