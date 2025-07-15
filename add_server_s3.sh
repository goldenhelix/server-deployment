#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if both email and password are provided
if [ $# -lt 3 ]; then
  echo "Error: A workspace, mount name, and bucket name must be provided."
  echo "Usage: $0 <workspace> <mount_name> <bucket_name>"
  exit 1
fi

workspace=$1
mount_name=$2
bucket_name=$3

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

# Write the modify_agents.sh script to the remote server and execute it
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem "$ADMIN_USER"@"$public_ip" << EOF
cat << 'SCRIPT' > /tmp/modify_agents.sh
#!/bin/bash

# Ensure the bucket name is provided
if [ -z "\$1" ]; then
  echo "Usage: \$0 <bucket_name> <mount_name> <agents_file>"
  exit 1
fi

mount_name="\$1"
bucket_name="\$2"
agents_file="\$3"

# Add cloud_storage_mounts to each section with instance_type
awk -v bucket_name="\$bucket_name" -v mount_name="\$mount_name"  '
/^  instance_type:/ {
  print
  print "  cloud_storage_mounts:"
  print "    " mount_name ": " bucket_name
  next
}
{ print }
' "\$agents_file" > "\${agents_file}.tmp" && mv "\${agents_file}.tmp" "\$agents_file" && chown ghuser:ghuser "\$agents_file"

echo "Updated \$agents_file with cloud_storage_mounts: { \"\$mount_name\": \"\$bucket_name\" }"
SCRIPT
chmod +x /tmp/modify_agents.sh
sudo /opt/ghserver/install.sh -y add_mount_s3 "${mount_name}" "${bucket_name}" \
&& sudo /tmp/modify_agents.sh "${mount_name}" "${bucket_name}" "/opt/ghserver/configs/agents.yaml" \
&& sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin workspace-add-share "${workspace}" "${mount_name}"'
EOF