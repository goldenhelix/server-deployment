#!/bin/bash

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both email and password are provided
if [ $# -lt 1 ]; then
  echo "Error: An admin email must be provided."
  echo "Usage: $0 <email>"
  exit 1
fi

# Admin email
email=$1

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

echo "Transferring configs/saml.yaml to the server..."
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Transfer the server_variables file to the server to opt/ghserver/configs/providers/aws/server_variables.tfvars
scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    configs/saml.yaml "$ADMIN_USER"@"$public_ip":/tmp/saml.yaml

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    configs/keys/idp_cert.pem "$ADMIN_USER"@"$public_ip":/tmp/idp_cert.pem

# Move the file to the desired location with the correct permissions
remote_path="/opt/ghserver/configs/saml.yaml"
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mv /tmp/saml.yaml $remote_path && \
    sudo chown ghuser:ghuser $remote_path && \
    sudo mv /tmp/idp_cert.pem /opt/ghserver/configs/keys/idp_cert.pem && \
    sudo chown ghuser:ghuser /opt/ghserver/configs/keys/idp_cert.pem && \
    sudo sed -i '/^auth_method:/ s/local/saml/' /opt/ghserver/config.yaml && \
    sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./restart.sh && ./ghadmin user-add \"${email}\" --admin'"