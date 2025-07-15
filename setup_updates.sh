#!/bin/bash
set -e

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

echo "Setting up unattended-upgrades with file configs/52unattended-upgrades-local"
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Copy the unattended-upgrades config to the server
scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
  configs/52unattended-upgrades-local "$ADMIN_USER@$public_ip:/tmp/52unattended-upgrades-local"

# Move it to the correct location with sudo
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
  "$ADMIN_USER@$public_ip" "sudo mv /tmp/52unattended-upgrades-local /etc/apt/apt.conf.d/52unattended-upgrades-local && sudo chown root:root /etc/apt/apt.conf.d/52unattended-upgrades-local"
