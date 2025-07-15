#!/bin/bash

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Run terraform output and store the result
terraform_output=$(cd "$TF_DIR" && $TF output -json)

# Extract values from terraform output
domain_name=$(echo $terraform_output | jq -r '.domain_name.value')
project_name=$(echo $terraform_output | jq -r '.project_name.value')
zone_name=$(echo $terraform_output | jq -r '.zone_name.value')
private_ip=$(echo $terraform_output | jq -r '.private_ip.value')
private_subnet_id=$(echo $terraform_output | jq -r '.private_subnet_id.value')
public_ip=$(echo $terraform_output | jq -r '.public_ip.value')

# Extract and format default tags
default_tags=$(echo $terraform_output | jq -r '.default_tags.value | to_entries | map("\"\(.key)\" = \"\(.value)\"") | join("\n  ")')


# Cloud-specific variables
if [ "$CLOUD_PROVIDER" = "aws" ]; then

  region=$(echo $terraform_output | jq -r '.region.value')
  vpc_id=$(echo $terraform_output | jq -r '.vpc_id.value')
  agents_security_group_id=$(echo $terraform_output | jq -r '.agents_security_group_id.value')
  agents_instance_profile_name=$(echo $terraform_output | jq -r '.agents_instance_profile_name.value')

  # Create the variables file for agent deployment
  cat << EOF > server_variables
domain_name          = "$domain_name"
project_name         = "$project_name"
zone_name            = "$zone_name"
aws_region           = "$region"
server_private_ip    = "$private_ip"
vpc_id               = "$vpc_id"
subnet_id            = "$private_subnet_id"
security_group_id    = "$agents_security_group_id"
iam_instance_profile = "$agents_instance_profile_name"
swap_size            = 4


aws_default_tags = {
  $default_tags
}
EOF
  # Move the file to the desired location with the correct permissions
  remote_path="/opt/ghserver/configs/providers/aws/server_variables.tfvars"

elif [ "$CLOUD_PROVIDER" = "azure" ]; then
  location=$(echo "$terraform_output" | jq -r '.location.value')
  availability_zone=$(echo "$terraform_output" | jq -r '.availability_zone.value')
  resource_group_name=$(echo "$terraform_output" | jq -r '.resource_group_name.value')
  subscription_id=$(echo "$terraform_output" | jq -r '.subscription_id.value')
  vnet_id=$(echo "$terraform_output" | jq -r '.vnet_id.value')
  agents_nsg_id=$(echo "$terraform_output" | jq -r '.agents_nsg_id.value')
  agents_managed_identity_id=$(echo "$terraform_output" | jq -r '.agents_managed_identity_id.value')

  # Create server variables file for Azure
  cat << EOF > server_variables
domain_name          = "$domain_name"
project_name         = "$project_name"
zone_name            = "$zone_name"
resource_group_name  = "$resource_group_name"
subscription_id      = "$subscription_id"
location             = "$location"
availability_zone    = "$availability_zone"
server_private_ip    = "$private_ip"
vnet_id              = "$vnet_id"
subnet_id            = "$private_subnet_id"
network_security_group_id = "$agents_nsg_id"
managed_identity_id  = "$agents_managed_identity_id"
swap_size            = 4

azure_tags = {
  $default_tags
}
EOF

  # Define remote storage path for Azure
  remote_path="/opt/ghserver/configs/providers/azure/server_variables.tfvars"

  # TODO: remove, this is temporary
  ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mkdir -p /opt/ghserver/configs/providers/azure && sudo chown ghuser:ghuser /opt/ghserver/configs/providers/azure"
fi

echo "Transferring server_variables file to the server..."

# Transfer the server_variables file to the server to /opt/ghserver/configs/providers/aws/server_variables.tfvars
scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    server_variables "$ADMIN_USER"@"$public_ip":/tmp/server_variables.tfvars

ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mv /tmp/server_variables.tfvars $remote_path && sudo chown ghuser:ghuser $remote_path"
