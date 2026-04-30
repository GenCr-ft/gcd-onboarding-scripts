#!/bin/bash

# ==============================================================================
# Script to configure the local environment for OpenTofu (GenCr@ft IaC)
# To be used by DevOps team members for manual operations.
#
# IMPORTANT - SECURITY:
# 1. AWS Credentials: This script assumes you have configured an AWS CLI profile
#    (via `aws configure --profile <profile-name>`).
#    This is the recommended method. Do NOT write your AWS keys here.
#    For enhanced security, explore tools like `aws-vault`.
# 2. GitHub Token: You will be prompted to enter your GitHub token.
#    It will not be stored in this script.
#
# USAGE:
# To ensure environment variables are defined in your CURRENT terminal session,
# you must "source" this script:
#
#   source ./setup-local-tofu-env.sh
#
#   OR (shorter equivalent):
#
#   . ./setup-local-tofu-env.sh
#
# After sourcing the script, navigate to the OpenTofu working directory
# (e.g., environments/github-org) and execute your `tofu` commands.
# ==============================================================================

echo "Configuring OpenTofu environment for GenCr@ft IaC (github-org)..."
echo ""

# --- 1. AWS Configuration ---
export AWS_REGION="eu-west-3"
export AWS_DEFAULT_REGION="eu-west-3" # Often used by AWS SDKs

echo "[AWS] AWS Region set to: ${AWS_REGION}"

# AWS Profile Management
# You can uncomment and adapt this section if you wish to choose a profile dynamically.
# Otherwise, ensure your default profile or the AWS_PROFILE variable is correctly set.
#----------------------------------------------------------------------------------------------------
# unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN # Unset direct keys if a profile is used

# if [ -z "$AWS_PROFILE" ]; then
#   read -r -p "AWS profile name to use (leave blank for default profile): " profile_name
#   if [ -n "$profile_name" ]; then
#     export AWS_PROFILE="$profile_name"
#     echo "[AWS] Using AWS profile: ${AWS_PROFILE}"
#   else
#     echo "[AWS] Using default AWS profile. Ensure it is configured for region ${AWS_REGION}."
#   fi
# else
#   echo "[AWS] Using AWS profile already defined in environment: ${AWS_PROFILE}"
# fi
#----------------------------------------------------------------------------------------------------
# Alternative (less secure, use only as a last resort and with caution):
# If you cannot use a profile, you could uncomment the following lines
# to enter your keys manually (they will only be valid for this session).
# read -s -r -p "Enter AWS Access Key ID: " aws_access_key_id_input
# export AWS_ACCESS_KEY_ID="$aws_access_key_id_input"
# echo ""
# read -s -r -p "Enter AWS Secret Access Key: " aws_secret_access_key_input
# export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key_input"
# echo ""
# read -s -r -p "Enter AWS Session Token (if applicable, otherwise leave blank): " aws_session_token_input
# if [ -n "$aws_session_token_input" ]; then
#   export AWS_SESSION_TOKEN="$aws_session_token_input"
# fi
# echo "[AWS] AWS credentials entered manually (for this session only)."
#----------------------------------------------------------------------------------------------------

echo "[AWS] Ensure your AWS credentials are accessible (via profile or other secure method)."
echo ""

# --- 2. GitHub Token for OpenTofu Provider ---
# This token requires the "repo" scope to manage private repositories.
if [[ -z "${TF_VAR_github_token}" ]]; then
    echo "[GitHub] The GitHub token (TF_VAR_github_token) is not defined."
    read -s -r -p "Please enter your GitHub Personal Access Token: " github_token_input
    export TF_VAR_github_token="$github_token_input"
    echo "" # New line after password input
    if [ -n "$TF_VAR_github_token" ]; then
        echo "[GitHub] GitHub token (TF_VAR_github_token) configured for this session."
    else
        echo "::warning::[GitHub] No GitHub token was provided. OpenTofu operations requiring GitHub authentication may fail."
    fi
else
    echo "[GitHub] GitHub token (TF_VAR_github_token) is already configured in this session."
fi
echo ""

# --- 3. OpenTofu Backend Variables (for information) ---
# These values are normally read from the `backend "s3" {}` configuration
# in your .tf files (e.g., backend.tf or main.tf).
# It is generally not necessary to export them here if `tofu init` is correctly executed.
# local TF_STATE_BUCKET_INFO="gft-ai-tfstate-eu-west-3"
# local TF_STATE_KEY_INFO="github-org/terraform.tfstate"
# local TF_DYNAMODB_TABLE_INFO="gft-ai-tfstate-lock-eu-west-3"
# echo "[OpenTofu Backend Info]"
# echo "  S3 Bucket     : ${TF_STATE_BUCKET_INFO}"
# echo "  State key     : ${TF_STATE_KEY_INFO}"
# echo "  DynamoDB Table: ${TF_DYNAMODB_TABLE_INFO}"
# echo ""

# --- Summary ---
echo "-----------------------------------------------------------------------"
echo "Environment variables configured for OpenTofu (partial):"
echo "  AWS_REGION          : ${AWS_REGION}"
echo "  AWS_DEFAULT_REGION  : ${AWS_DEFAULT_REGION}"
# if [ -n "$AWS_PROFILE" ]; then echo "  AWS_PROFILE         : ${AWS_PROFILE}"; fi
echo "  TF_VAR_github_token : ${TF_VAR_github_token:+"******** (defined)"}"
echo "-----------------------------------------------------------------------"
echo ""
echo "Environment configuration complete."
echo "Don't forget to navigate to the appropriate working directory"
echo "(e.g., 'cd environments/github-org') before running 'tofu init'."
echo "As a reminder, this script must be sourced: '. ./setup-local-tofu-env.sh'"
