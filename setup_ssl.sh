#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both email and password are provided
if [ $# -lt 2 ]; then
  echo "Error: Both SSL certificate and SSL key must be provided."
  echo "Usage: $0 <ssl_cert> <ssl_key>"
  exit 1
fi

ssl_cert=$1
ssl_key=$2

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    $ssl_cert "$ADMIN_USER"@"$public_ip":/tmp/cert.pem

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    $ssl_key "$ADMIN_USER"@"$public_ip":/tmp/key.pem

cert_path="/opt/ghserver/certs/cert.pem"
key_path="/opt/ghserver/certs/key.pem"

# Move the certificate and key to the correct location, and set the correct permissions and owner
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mv /tmp/cert.pem $cert_path && \
    sudo mv /tmp/key.pem $key_path && \
    sudo chown ghuser:ghuser $cert_path $key_path && \
    sudo chmod 600 $key_path && \
    cd /opt/ghserver && \
    sudo -u ghuser docker compose restart web"
