#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if mount name, az_account_name, az_account_key and az_account_container are provided
if [ $# -lt 4 ]; then
  echo "Error: A mount name, az_account_name, az_account_key and az_account_container must be provided."
  echo "Usage: $0 <mount_name> <az_account_name> <az_account_key> <az_account_container>"
  exit 1
fi

mount_name=$1
az_account_name=$2
az_account_key=$3
az_account_container=$4

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo /opt/ghserver/install.sh -y add_mount_azure \"${mount_name}\" \"${az_account_name}\" \"${az_account_key}\" \"${az_account_container}\""