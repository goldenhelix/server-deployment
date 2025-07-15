#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both email and password are provided
if [ $# -lt 1 ]; then
  echo "Error: A license key must be provided."
  echo "Usage: $0 <sentieon_license_file>"
  exit 1
fi

sentieon_license_file=$1

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$sentieon_license_file" "$ADMIN_USER"@"$public_ip":/tmp/sentieon.lic

remote_path="/opt/ghserver/configs/sentieon.lic"


ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mv /tmp/sentieon.lic $remote_path && \
    sudo chown ghuser:ghuser $remote_path && \
    sudo /opt/ghserver/install.sh -y add_sentieon_service $remote_path "