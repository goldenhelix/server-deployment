#!/bin/bash

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Determine which config file to use based on cloud provider
if [ "$CLOUD_PROVIDER" = "aws" ]; then
  CONFIG_FILE="configs/agents_aws.yaml"
elif [ "$CLOUD_PROVIDER" = "azure" ]; then
  CONFIG_FILE="configs/agents_azure.yaml"
else
  echo "Error: Unsupported cloud provider: $CLOUD_PROVIDER"
  exit 1
fi

echo "Transferring $CONFIG_FILE to the server..."
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$CONFIG_FILE" "$ADMIN_USER"@"$public_ip":/tmp/agents.yaml

# Append the file to the desired location with the correct permissions
remote_path="/opt/ghserver/configs/agents.yaml"
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo cat /tmp/agents.yaml | sudo tee -a $remote_path > /dev/null && \
    sudo chown ghuser:ghuser $remote_path && \
    sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin server-reload-auth'"
