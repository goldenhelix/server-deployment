#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both email and password are provided
if [ $# -lt 2 ]; then
  echo "Error: Both email and password must be provided."
  echo "Usage: $0 <email> <password>"
  exit 1
fi

# Parse out the email and password from the command line arguments
email=$1
password=$2

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Run this command on the server to add the user
if ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "set -e; sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin user-add \"${email}\" --admin --password \"${password}\"'"; then
  echo "User $email with password $password has been added to the server."
else
  echo "Failed to add user $email to the server."
fi