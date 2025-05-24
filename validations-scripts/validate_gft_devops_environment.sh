#!/bin/bash
# Script: validate_gft_devops_environment_proj103.sh
# Description: Validates the presence and critical configuration of essential DevOps tools
#              specifically for executing PROJ-103 (GitHub restructuring & IaC setup)
#              within the Gencraft studio environment. Optimized for WSL/Ubuntu.
# Version: 1.4
# Author: Gencraft DevOps Team (Adam, Benjamin, Camille, Diane, Édouard)
# SSoT: gencraft-devops-automation/validation-scripts/validate_gft_devops_environment_proj103.sh
# Usage: ./validate_gft_devops_environment_proj103.sh

# --- Configuration - Versions Minimales Attendues (À synchroniser avec les SSoT Gencraft) ---
EXPECTED_OPENTOFU_VERSION_MAJOR=1
EXPECTED_OPENTOFU_VERSION_MINOR=6
EXPECTED_PYTHON_VERSION_MAJOR=3
EXPECTED_PYTHON_VERSION_MINOR=8
EXPECTED_GIT_VERSION_MAJOR=2
EXPECTED_GH_VERSION_MAJOR=2 # GitHub CLI
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
}

print_status() {
    local prefix
    case "$2" in
        OK)    prefix="[${GREEN}OK${NC}]    ";;
        FAIL)  prefix="[${RED}FAIL${NC}]  "; ((FAIL_COUNT++));;
        WARN)  prefix="[${YELLOW}WARN${NC}]  "; ((WARN_COUNT++));;
        INFO)  prefix="[${CYAN}INFO${NC}]  ";;
        *)     prefix="[????]  ";;
    esac
    echo -e "$prefix$1"
}

check_command_exists() {
    local cmd="$1"
    local desc="$2"
    local ref="$3"
    local install_suggestion_ubuntu="$4" # Installation suggestion for Ubuntu/WSL
    local install_suggestion_other="$5"  # Optional: for other OS like macOS
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
            if [[ "$install_suggestion_ubuntu" == *"sudo"* || "$install_suggestion_ubuntu" == *"apt"* ]]; then
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
}

check_version() {
    local version_cmd="$1"
    local tool_name="$2"
    local expected_major="$3"
    local expected_minor="$4"
    local version_regex_extract="$5"
    local version_cmd_output
    local current_version current_major current_minor

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
}

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
if check_command_exists "git" "Git" "" "sudo apt update && sudo apt install git"; then
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
if check_command_exists "gh" "GitHub CLI" "" "Consultez https://github.com/cli/cli#installation (suivre les instructions pour Linux/Debian/Ubuntu)"; then
    check_version "gh --version" "GitHub CLI" "$EXPECTED_GH_VERSION_MAJOR" 0 'gh version \K([0-9]+\.[0-9]+(\.[0-9]+)?)'

    print_status "Vérification de l'authentification GitHub CLI (gh auth status)..." "INFO"
    if gh auth status > /dev/null 2>&1; then
        GH_USER=$(gh auth status -h github.com --show-token 2>/dev/null | grep "Logged in to github.com as" | sed 's/.*Logged in to github.com as \([^ ]*\) .*/\1/')
        print_status "GitHub CLI (gh): Authentifié en tant que '$GH_USER'." "OK"
        print_status "Permissions pour PROJ-103: Vérification MANUELLE requise." "WARN"
        print_status "  L'utilisateur authentifié ('$GH_USER') DOIT avoir les droits d'administration" "INFO"
        print_status "  sur l'organisation '$ORGANIZATION' ou des permissions spécifiques étendues" "INFO"
        print_status "  pour renommer/créer des dépôts et gérer les permissions/webhooks." "INFO"
        print_status "  Consultez /documentation/GenCr-ft/gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Security/Access-Control-Policy.md et S8." "INFO"
    else
        print_status "GitHub CLI (gh): Non authentifié." "FAIL"
        print_status "  Veuillez exécuter 'gh auth login' et vous assurer d'avoir les permissions nécessaires pour l'organisation GenCr-ft." "INFO"
    fi
fi

# 3. OpenTofu (tofu)
print_header "3" "OpenTofu (tofu) - IaC Tool"
if check_command_exists "tofu" "OpenTofu" "/documentation/GenCr-ft/devops-standards/iac/IAC_001_Tooling_Standard_OpenTofu.md" "Consultez https://opentofu.org/docs/intro/install (suivre les instructions pour Linux/Debian/Ubuntu)"; then
    check_version "tofu version" "OpenTofu" "$EXPECTED_OPENTOFU_VERSION_MAJOR" "$EXPECTED_OPENTOFU_VERSION_MINOR" 'OpenTofu v\K([0-9]+\.[0-9]+(\.[0-9]+)?)'
fi

# 4. Outils de Traitement de Données (jq)
print_header "4" "Outils de Traitement de Données"
check_command_exists "jq" "jq (JSON processor)" "sudo apt install jq"

# 5. Outils de Linting et Qualité de Code
print_header "5" "Outils de Linting et Qualité"
check_command_exists "mdl" "Markdownlint (mdl)" "/documentation/GenCr-ft/gencraft-studio-handbook/04-Tooling-And-Automation-Hub/Tools/GCT-TOOL-MDLINT-V1.md" "sudo apt install ruby-full build-essential && sudo gem install mdl"
check_command_exists "tflint" "TFLint (OpenTofu Linter)" "Consultez https://github.com/terraform-linters/tflint#installation (souvent un binaire à télécharger)"
check_command_exists "tfsec" "TFSec (IaC Security Scanner)" "Consultez https://aquasecurity.github.io/tfsec/latest/getting-started/installation/ (souvent un binaire à télécharger)"
# Ou Checkov comme alternative/complément
# check_command_exists "checkov" "Checkov (IaC Security Scanner)" "pip3 install checkov"

if check_command_exists "python3" "Python 3" "" "sudo apt install python3 python3-pip"; then
    check_version "python3 --version" "Python 3" "$EXPECTED_PYTHON_VERSION_MAJOR" "$EXPECTED_PYTHON_VERSION_MINOR" 'Python \K([0-9]+\.[0-9]+(\.[0-9]+)?)'
    if check_command_exists "pip3" "pip3 (Python Package Installer)"; then # pip3 est généralement installé avec python3-pip
        check_command_exists "pre-commit" "pre-commit framework" "/documentation/GenCr-ft/devops-standards/tooling/TOOL_004_Git_Hooks_Standard.md (à créer)" "pip3 install pre-commit"
    fi
fi

# --- Résumé Final ---
echo ""
echo "======================================================================"
echo "Résumé de la Validation de l'Environnement DevOps pour PROJ-103 :"
if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    print_status "Tous les outils vérifiés sont PRÉSENTS et CONFORMES aux versions de base." "OK"
    print_status "N'oubliez pas la VÉRIFICATION MANUELLE des permissions 'gh' étendues." "INFO"
elif [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -gt 0 ]; then
    print_status "Tous les outils essentiels sont présents, mais $WARN_COUNT AVERTISSEMENT(S) subsiste(nt)." "WARN"
    print_status "  Cela inclut potentiellement la configuration Git et la nécessité de vérifier les permissions 'gh'." "INFO"
else
    print_status "$FAIL_COUNT ERREUR(S) critique(s) détectée(s). $WARN_COUNT AVERTISSEMENT(S) également présent(s)." "FAIL"
    print_status "Veuillez corriger les ERREURS pour pouvoir exécuter les opérations de PROJ-103." "FAIL"
fi
echo "Consultez les standards Gencraft pour les versions exactes et les configurations détaillées."
echo "  - OpenTofu: /documentation/GenCr-ft/devops-standards/iac/IAC_001_Tooling_Standard_OpenTofu.md"
echo "  - GitHub CLI: /documentation/GenCr-ft/devops-standards/tooling/TOOL_00X_GH_CLI_Standard.md (ou équivalent)"
echo "  - Hooks Git: /documentation/GenCr-ft/devops-standards/tooling/TOOL_004_Git_Hooks_Standard.md (à créer)"
echo "======================================================================"

exit $FAIL_COUNT
