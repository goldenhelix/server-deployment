#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

if [ $# -lt 1 ]; then
  echo "Error: Server name must be provided."
  echo "Usage: $0 <server_name>"
  exit 1
fi

server_name=$1

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin server-set-name \"${server_name}\"'"
