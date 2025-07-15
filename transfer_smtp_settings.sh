#!/bin/bash

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

echo "Transferring configs/smtp.yaml to the server..."
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Transfer the server_variables file to the server to opt/ghserver/configs/providers/aws/server_variables.tfvars
scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    configs/smtp.yaml "$ADMIN_USER"@"$public_ip":/tmp/smtp.yaml

# Move the file to the desired location with the correct permissions
remote_path="/opt/ghserver/configs/smtp.yaml"
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mv /tmp/smtp.yaml $remote_path && \
    sudo chown ghuser:ghuser $remote_path && \
    sudo sed -i '/^smtp_enabled:/ s/false/true/' /opt/ghserver/config.yaml && \
    sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin server-reload-auth'"
