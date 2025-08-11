#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both workspace and mount name are provided
if [ $# -lt 2 ]; then
  echo "Error: A workspace and mount name must be provided."
  echo "Usage: $0 <workspace> <mount_name>"
  exit 1
fi

workspace=$1
mount_name=$2

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Add the share to the workspace
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin workspace-add-share \"${workspace}\" \"${mount_name}\"'" 