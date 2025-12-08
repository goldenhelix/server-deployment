#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if mount name, account name and container name are provided
# Account key is optional (3 or 4 parameters)
if [ $# -lt 3 ]; then
  echo "Error: A mount name, account name and container name must be provided."
  echo "Usage: $0 <mount_name> <account_name> <container_name> [<account_key>]"
  exit 1
fi

mount_name=$1
account_name=$2
container_name=$3

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# If 4 parameters are provided, account_key is included (at the end)
# If 3 parameters are provided, account_key is omitted
if [ $# -eq 4 ]; then
  account_key=$4
  # Add the Azure blob storage to the server with credentials
  ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
      "$ADMIN_USER"@"$public_ip" "sudo /opt/ghserver/install.sh -y add_mount_azure \"${mount_name}\" \"${account_name}\" \"${container_name}\" \"${account_key}\""
else
  # Add the Azure blob storage to the server, when no credentials are provided, the
  # server will also set the account name and container name in mounts.yaml as an
  # agent cloud bucket to be mounted.
  ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
      "$ADMIN_USER"@"$public_ip" "sudo /opt/ghserver/install.sh -y add_mount_azure \"${mount_name}\" \"${account_name}\" \"${container_name}\""
fi