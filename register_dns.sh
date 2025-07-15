#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both email and password are provided
if [ $# -lt 2 ]; then
  echo "Error: Both license key and domain name must be provided."
  echo "Usage: $0 <license_key> <domain_name>"
  exit 1
fi

license_key=$1
domain_name=$2

# subdomain is the first part of the domain name
subdomain=$(echo $domain_name | cut -d'.' -f1)

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    configs/update-cert.sh "$ADMIN_USER"@"$public_ip":/tmp/update-cert.sh

remote_path="/opt/ghserver/update-cert.sh"

# Set up a cron that runs every month to renew the certificate and run it now
#  --license-key "S-13a699-a2defd-68e066-33506e" --subdomain "fccc-test" --ip "192.168.1.1"
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mv /tmp/update-cert.sh $remote_path && \
    sudo chown ghuser:ghuser $remote_path && \
    sudo chmod +x $remote_path && \
    sudo -u ghuser $remote_path --license-key \"$license_key\" --subdomain \"$subdomain\" --ip \"$public_ip\" && \
    sudo -u ghuser crontab -l | { cat; echo \"0 3 1 * * $remote_path --license-key \\\"$license_key\\\" --subdomain \\\"$subdomain\\\" --ip \\\"$public_ip\\\"\"; } | sudo  -u ghuser crontab -"
