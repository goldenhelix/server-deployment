#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

echo "Starting server instance..."
cd "$TF_DIR"
$TF init -upgrade=false

# Check if secrets.tfvars file exists
if [ -f secrets.tfvars ]; then
  echo "Using secrets.tfvars file for $CLOUD_PROVIDER credentials"
  TF_VAR_FILE_ARG="-var-file=secrets.tfvars"
else
  TF_VAR_FILE_ARG=""
fi

echo "Destroying the server and its resources..."
$TF destroy -auto-approve $TF_VAR_FILE_ARG
