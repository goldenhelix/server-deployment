#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

if [ $# -lt 1 ]; then
  echo "Error: A locale must be provided."
  echo "Usage: $0 <locale>"
  exit 1
fi

locale=$1

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo sh -c '
        # Uncomment the locale in /etc/locale.gen
        sed -i \"s/# ${locale}/${locale}/\" /etc/locale.gen
        
        # Generate the locale
        locale-gen
        
        # Set locale using update-locale
        update-locale LANG=${locale}
        
        # Also set in /etc/locale.conf for systemd compatibility
        echo \"LANG=${locale}\" > /etc/locale.conf

        # Disable locale warning for cloud-init
        touch /var/lib/cloud/instance/locale-check.skip
        
        # Update environment for current session
        export LANG=${locale}
    ' && \
    sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && if ! grep -q \"^LC_ALL:\" config.yaml; then echo \"LC_ALL: ${locale}\" >> config.yaml; fi && ./ghadmin server-reload-auth'"