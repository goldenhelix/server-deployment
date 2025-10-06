#!/bin/bash

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

cd "$TF_DIR"
$TF init -upgrade=false
cd - || exit

# Get ssh key if generated (otherwise we expect it to be at ./ssh_key.pem)
generated_key=$(cd "$TF_DIR" && $TF output -raw generated_ssh_private_key)

if [[ -n "$generated_key" ]]; then
  rm -rf ssh_key.pem
  echo "$generated_key" > ssh_key.pem && chmod 400 ssh_key.pem
fi

ssh -i ssh_key.pem "$ADMIN_USER"@$(cd "$TF_DIR" && $TF output -raw public_ip)
