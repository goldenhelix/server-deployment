#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if mount name, dx_api_token and dx_project_name are provided
if [ $# -lt 3 ]; then
  echo "Error: A mount name, dx_api_token and dx_project_name must be provided."
  echo "Usage: $0 <mount_name> <dx_api_token> <dx_project_name>"
  exit 1
fi

mount_name=$1
dx_api_token=$2
dx_project_name=$3

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo /opt/ghserver/install.sh -y add_mount_dna_nexus \"${mount_name}\" \"${dx_api_token}\" \"${dx_project_name}\""