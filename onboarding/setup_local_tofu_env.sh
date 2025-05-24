#!/bin/bash

# ==============================================================================
# Script pour configurer l'environnement local pour OpenTofu (Gencraft IaC)
# À utiliser par les membres de l'équipe DevOps pour des opérations manuelles.
#
# IMPORTANT - SÉCURITÉ :
# 1. Identifiants AWS : Ce script part du principe que vous avez configuré
#    un profil AWS CLI (via `aws configure --profile <nom-du-profil>`).
#    C'est la méthode recommandée. N'écrivez PAS vos clés AWS ici.
#    Pour une sécurité renforcée, explorez des outils comme `aws-vault`.
# 2. Token GitHub : Vous serez invité à saisir votre token GitHub.
#    Il ne sera pas stocké dans ce script.
#
# USAGE :
# Pour que les variables d'environnement soient définies dans votre session
# terminal ACTUELLE, vous devez "sourcer" ce script :
#
#   source ./setup_local_tofu_env.sh
#
#   OU (équivalent plus court) :
#
#   . ./setup_local_tofu_env.sh
#
# Après avoir sourcé le script, naviguez vers le répertoire de travail OpenTofu
# (ex: environments/github-org) et exécutez vos commandes `tofu`.
# ==============================================================================

echo "Configuration de l'environnement OpenTofu pour Gencraft IaC (github-org)..."
echo ""

# --- 1. Configuration AWS ---
export AWS_REGION="eu-west-3"
export AWS_DEFAULT_REGION="eu-west-3" # Souvent utilisé par les SDK AWS

echo "[AWS] Région AWS définie sur : ${AWS_REGION}"

# Gestion du profil AWS
# Vous pouvez décommenter et adapter cette section si vous souhaitez choisir un profil dynamiquement.
# Sinon, assurez-vous que votre profil par défaut ou la variable AWS_PROFILE est correctement positionnée.
#----------------------------------------------------------------------------------------------------
# unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN # Dé-setter les clés directes si un profil est utilisé

# if [ -z "$AWS_PROFILE" ]; then
#   read -r -p "Nom du profil AWS à utiliser (laisser vide pour le profil par défaut) : " profile_name
#   if [ -n "$profile_name" ]; then
#     export AWS_PROFILE="$profile_name"
#     echo "[AWS] Utilisation du profil AWS : ${AWS_PROFILE}"
#   else
#     echo "[AWS] Utilisation du profil AWS par défaut. Assurez-vous qu'il est configuré pour la région ${AWS_REGION}."
#   fi
# else
#   echo "[AWS] Utilisation du profil AWS déjà défini dans l'environnement : ${AWS_PROFILE}"
# fi
#----------------------------------------------------------------------------------------------------
# Alternative (moins sécurisée, à n'utiliser qu'en dernier recours et avec prudence) :
# Si vous ne pouvez pas utiliser de profil, vous pourriez décommenter les lignes suivantes
# pour saisir vos clés manuellement (elles ne seront valides que pour cette session).
# read -s -r -p "Saisir AWS Access Key ID : " aws_access_key_id_input
# export AWS_ACCESS_KEY_ID="$aws_access_key_id_input"
# echo ""
# read -s -r -p "Saisir AWS Secret Access Key : " aws_secret_access_key_input
# export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key_input"
# echo ""
# read -s -r -p "Saisir AWS Session Token (si applicable, sinon laisser vide) : " aws_session_token_input
# if [ -n "$aws_session_token_input" ]; then
#   export AWS_SESSION_TOKEN="$aws_session_token_input"
# fi
# echo "[AWS] Identifiants AWS saisis manuellement (pour cette session uniquement)."
#----------------------------------------------------------------------------------------------------

echo "[AWS] Assurez-vous que vos identifiants AWS sont accessibles (via profil ou autre méthode sécurisée)."
echo ""

# --- 2. Token GitHub pour le Provider OpenTofu ---
# Ce token nécessite le scope "repo" pour gérer les dépôts privés.
if [[ -z "${TF_VAR_github_token}" ]]; then
    echo "[GitHub] Le token GitHub (TF_VAR_github_token) n'est pas défini."
    read -s -r -p "Veuillez saisir votre token d'accès personnel GitHub : " github_token_input
    export TF_VAR_github_token="$github_token_input"
    echo "" # Nouvelle ligne après la saisie du mot de passe
    if [ -n "$TF_VAR_github_token" ]; then
        echo "[GitHub] Token GitHub (TF_VAR_github_token) configuré pour cette session."
    else
        echo "::warning::[GitHub] Aucun token GitHub n'a été fourni. Les opérations OpenTofu nécessitant une authentification GitHub risquent d'échouer."
    fi
else
    echo "[GitHub] Token GitHub (TF_VAR_github_token) est déjà configuré dans cette session."
fi
echo ""

# --- 3. Variables OpenTofu Backend (pour information) ---
# Ces valeurs sont normalement lues depuis la configuration `backend "s3" {}`
# dans vos fichiers .tf (ex: backend.tf ou main.tf).
# Il n'est généralement pas nécessaire de les exporter ici si `tofu init` est correctement exécuté.
# local TF_STATE_BUCKET_INFO="gft-ai-tfstate-eu-west-3"
# local TF_STATE_KEY_INFO="github-org/terraform.tfstate"
# local TF_DYNAMODB_TABLE_INFO="gft-ai-tfstate-lock-eu-west-3"
# echo "[OpenTofu Backend Info]"
# echo "  Bucket S3    : ${TF_STATE_BUCKET_INFO}"
# echo "  Clé d'état   : ${TF_STATE_KEY_INFO}"
# echo "  Table DynamoDB: ${TF_DYNAMODB_TABLE_INFO}"
# echo ""

# --- Résumé ---
echo "-----------------------------------------------------------------------"
echo "Variables d'environnement configurées pour OpenTofu (partiel) :"
echo "  AWS_REGION          : ${AWS_REGION}"
echo "  AWS_DEFAULT_REGION  : ${AWS_DEFAULT_REGION}"
# if [ -n "$AWS_PROFILE" ]; then echo "  AWS_PROFILE         : ${AWS_PROFILE}"; fi
echo "  TF_VAR_github_token : ${TF_VAR_github_token:+"******** (défini)"}"
echo "-----------------------------------------------------------------------"
echo ""
echo "Configuration de l'environnement terminée."
echo "N'oubliez pas de naviguer vers le répertoire de travail approprié"
echo "(ex: 'cd environments/github-org') avant de lancer 'tofu init'."
echo "Pour rappel, ce script doit être sourcé : '. ./setup_local_tofu_env.sh'"
