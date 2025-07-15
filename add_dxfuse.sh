#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both email and password are provided
if [ $# -lt 4 ]; then
  echo "Error: A workspace, mount name, dx_api_token and dx_project_name must be provided."
  echo "Usage: $0 <workspace> <mount_name> <dx_api_token> <dx_project_name>"
  exit 1
fi

workspace=$1
mount_name=$2
dx_api_token=$3
dx_project_name=$4

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo /opt/ghserver/install.sh -y add_mount_dna_nexus \"${mount_name}\" \"${dx_api_token}\" \"${dx_project_name}\" \
    && sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin workspace-add-share \"${workspace}\" \"${mount_name}\"'"