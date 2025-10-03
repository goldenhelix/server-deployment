#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Install admin console service and capture the output
admin_console_output=$(ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo /opt/ghserver/install.sh -y add_admin_console_service")

# Append admin console information to status.txt
echo "=== Admin Console ===" >> status.txt
echo "$admin_console_output" | grep "The admin console" >> status.txt
echo "" >> status.txt

echo "$admin_console_output"
