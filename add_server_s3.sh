#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both mount name and bucket name are provided
if [ $# -lt 2 ]; then
  echo "Error: A mount name and bucket name must be provided."
  echo "Usage: $0 <mount_name> <bucket_name>"
  exit 1
fi

mount_name=$1
bucket_name=$2

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Add the S3 bucket to the server, when no credentials are provided, the server
# will also set the bucket name in mounts.yaml as an agent cloud bucket to be mounted.
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
 "$ADMIN_USER"@"$public_ip" "sudo /opt/ghserver/install.sh -y add_mount_s3 \"${mount_name}\" \"${bucket_name}\""