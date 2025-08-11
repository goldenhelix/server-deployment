#!/bin/bash
set -eo pipefail

# This script is used to continue a server instance that was created with create_server.sh but interrupted
# Comment out lines that are not needed for the server instance you are continuing

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Function to handle errors
error_handler() {
    local line_no=$1
    local error_code=$?
    echo "Error occurred in script at line: $line_no"
    echo "Exit code of last command: $error_code"
    echo "Last command: ${BASH_COMMAND}"
    exit 1
}
START_TIME=$(date +%s)

trap 'error_handler ${LINENO}' ERR

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

echo "Continuing server instance..."

cd "$TF_DIR"

# Get the agent private IP
public_ip=$($TF output -raw public_ip)
domain_name=$($TF output -raw domain_name)

echo "Server instance created with public IP: $public_ip"

# Get ssh key if generated (otherwise we expect it to be at ./ssh_key.pem)
generated_key=$($TF output -raw generated_ssh_private_key)

# Run remaining commands in the root folder
cd - || exit

if [[ -n "$generated_key" ]]; then
  rm -rf ssh_key.pem
  echo "$generated_key" > ssh_key.pem && chmod 400 ssh_key.pem
fi

echo "Transferring server settings..."

#Ensure our helper scripts are executable
chmod +x ./*.sh

email=$(cd "$TF_DIR" && $TF output -raw email)

# Transform output state to the server as /opt/ghserver/configs/providers/aws/server_variables.tfvars
./transfer_server_variables.sh

# Set time zone on the server
./set_timezone.sh "${TIMEZONE}"

# Set default locale on the server
./set_locale.sh "${LOCALE}"

# Set the server name
./set_server_name.sh "${SERVER_NAME}"

# Set up scheduled reboot on the first Saturday of the month at 10pm
./setup_scheduled_reboot.sh

if [ -n "${SSL_CERT:-}" ] && [ -n "${SSL_KEY:-}" ]; then
    # Set up SSL using provided certificate and key
    ./setup_ssl.sh "${SSL_CERT}" "${SSL_KEY}"
elif [[ "${domain_name}" == *.varseq.com ]]; then
    # Register DNS and server SSL certificate for varseq.com domain
    ./register_dns.sh "${LICENSE_KEY}" "${domain_name}"
else
    echo "You must manually update the DNS record for $domain_name to point to $public_ip"
    echo "If your server is publicly accessible, it will receive a Let's Encrypt certificate automatically"
    echo "Otherwise, review the documentation for manual certificate installation"
fi

# Add the admin console service on :4433
./add_admin_console.sh

# Set up unattended-upgrades with file configs/52unattended-upgrades-local
./setup_updates.sh

# Set up dynamic agent configuration (based on configs/agents_aws.yaml or configs/agents_azure.yaml)
./transfer_agents_config.sh

email=$(cd "$TF_DIR" && $TF output -raw email)
if [ "$SETUP_SAML" = true ]; then
    # Transfer SAML settings
    ./transfer_saml_settings.sh "${email}"
else
  echo "Setting up admin user..."
    # Generate a printable password and add the admin user
    password=$(openssl rand -base64 18)
    ./add_admin.sh "${email}" "${password}"
fi

# docker images
./setup_agent_images.sh

# Transfer SMTP server settings
./transfer_smtp_settings.sh

# Activate the license, requires that email is registered with Golden Helix
./activate_license.sh "${LICENSE_KEY}" "${email}"

# Create the primary workspace (assembly can be hg19 or hg38)
./create_workspace.sh "${WORKSPACE}" "${WORKSPACE_NAME}" "${WORKSPACE_ASSEMBLY}"

# Create the second workspace if variables are defined
if [ -n "${WORKSPACE2:-}" ] && [ -n "${WORKSPACE2_NAME:-}" ] && [ -n "${WORKSPACE2_ASSEMBLY:-}" ]; then
    echo "Creating second workspace: ${WORKSPACE2_NAME} (${WORKSPACE2_ASSEMBLY})"
    ./create_workspace.sh "${WORKSPACE2}" "${WORKSPACE2_NAME}" "${WORKSPACE2_ASSEMBLY}"
fi

# add user to primary workspace
./invite_user.sh "${WORKSPACE}" "${email}" "admin"

# add user to second workspace if it exists
if [ -n "${WORKSPACE2:-}" ]; then
    ./invite_user.sh "${WORKSPACE2}" "${email}" "admin"
fi

# Add the created S3 bucket for workspace storage
if [ "$CLOUD_PROVIDER" = "aws" ]; then
    # TODO: We should have this be called ./add_server_agent_bucket or ./add_server_agent_storage
    # Most of it is cloud agnostic, we just need the tmp/install.sh -y add_mount_(*) part
    s3_bucket=$(cd "$TF_DIR" && $TF output -raw bucket_name)
    ./add_server_s3.sh CloudStorage "${s3_bucket}"
    ./add_workspace_share.sh "${WORKSPACE}" CloudStorage
    # Add storage to second workspace if it exists
    if [ -n "${WORKSPACE2:-}" ]; then
        ./add_workspace_share.sh "${WORKSPACE2}" CloudStorage
    fi
elif [ "$CLOUD_PROVIDER" = "azure" ]; then
    storage_account_name=$(cd "$TF_DIR" && $TF output -raw storage_account_name)
    storage_container_name=$(cd "$TF_DIR" && $TF output -raw storage_container_name)
    ./add_server_azure.sh "CloudStorage" "${storage_account_name}" "${storage_container_name}"
    ./add_workspace_share.sh "${WORKSPACE}" CloudStorage
    # Add storage to second workspace if it exists
    if [ -n "${WORKSPACE2:-}" ]; then
        ./add_workspace_share.sh "${WORKSPACE2}" CloudStorage
    fi
fi

# Set up Sentieon license
if [ -n "${SENTIEON_LICENSE_FILE}" ]; then
    ./add_sentieon.sh "${SENTIEON_LICENSE_FILE}" # Replaces 
fi

# Set up DNAnexus fuse mount
if [ -n "${DX_MOUNT_NAME}" ] && [ -n "${DX_API_TOKEN}" ] && [ -n "${DX_PROJECT_NAME}" ]; then
    ./add_dxfuse.sh "${DX_MOUNT_NAME}" "${DX_API_TOKEN}" "${DX_PROJECT_NAME}"
    ./add_workspace_share.sh "${WORKSPACE}" "${DX_MOUNT_NAME}"
    # Add mount to second workspace if it exists
    if [ -n "${WORKSPACE2:-}" ]; then
        ./add_workspace_share.sh "${WORKSPACE2}" "${DX_MOUNT_NAME}"
    fi
fi

# Set up BaseSpace mount
if [ -n "${BASESPACE_MOUNT_NAME}" ] && [ -n "${BASESPACE_API_TOKEN}" ]; then
    ./add_basespace.sh "${BASESPACE_MOUNT_NAME}" "${BASESPACE_API_TOKEN}"
    ./add_workspace_share.sh "${WORKSPACE}" "${BASESPACE_MOUNT_NAME}"
    # Add mount to second workspace if it exists
    if [ -n "${WORKSPACE2:-}" ]; then
        ./add_workspace_share.sh "${WORKSPACE2}" "${BASESPACE_MOUNT_NAME}"
    fi
fi

# Set up Azure Blob Storage mount
if [ -n "${AZURE_MOUNT_NAME}" ] && [ -n "${AZURE_ACCOUNT_NAME}" ] && [ -n "${AZURE_ACCOUNT_KEY}" ] && [ -n "${AZURE_ACCOUNT_CONTAINER}" ]; then
    ./add_azure_blob.sh "${AZURE_MOUNT_NAME}" "${AZURE_ACCOUNT_NAME}" "${AZURE_ACCOUNT_KEY}" "${AZURE_ACCOUNT_CONTAINER}"
    ./add_workspace_share.sh "${WORKSPACE}" "${AZURE_MOUNT_NAME}"
    # Add mount to second workspace if it exists
    if [ -n "${WORKSPACE2:-}" ]; then
        ./add_workspace_share.sh "${WORKSPACE2}" "${AZURE_MOUNT_NAME}"
    fi
fi

# Start the process of rebuilding the agent images (this will take a while and should not be interrupted by server restarts)
echo "Rebuilding agent images..."
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo -u ghuser /bin/bash -c 'cd /opt/ghserver && ./ghadmin agent-rebuild-image ${CLOUD_PROVIDER:-aws}'"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "Server ${domain_name} created in $DURATION seconds at IP: ${public_ip}"
if [ "$SETUP_SAML" = true ]; then
    echo "You can log in with the following email: $email"
else 
    echo "You can log in with the following admin credentials:"
    echo "  Email: $email"
    echo "  Password: $password"
fi