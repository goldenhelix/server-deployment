#!/bin/bash

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

echo "Transferring configs/agent_images and adding the default docker image..."
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    configs/agent_images "$ADMIN_USER"@"$public_ip":/tmp/agent_images

ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    admin@"$public_ip" "sudo cat /tmp/agent_images | sudo tee -a $remote_path > /dev/null"

remote_path="/opt/ghserver/configs/providers/agent_images"
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo cat /tmp/agent_images | sudo tee -a $remote_path > /dev/null"

ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "while read -r image; do \
    echo \"Pulling \$image...\" && \
    sudo -u ghuser docker pull \"\$image\"; \
    done < $remote_path"
