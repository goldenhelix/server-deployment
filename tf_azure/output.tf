# Purpose: Define the output variables for the Golden Helix Deployment

output "location" {
  value = var.location
}

output "availability_zone" {
  value = var.availability_zone
}

output "subscription_id" {
  value = var.subscription_id
}

output "project_name" {
  value = var.project_name
}

output "zone_name" {
  value = var.server_zone_name
}

output "domain_name" {
  value = var.domain_name
}

output "ssh_key_name" {
  value = module.standard.ssh_key_name
}

output "resource_group_name" {
  value = module.standard.resource_group_name
}

output "resource_group_id" {
  value = module.standard.resource_group_id
} 

output "generated_ssh_public_key" {
  value = module.standard.generated_ssh_public_key
}

output "generated_ssh_private_key" {
  value     = module.standard.generated_ssh_private_key
  sensitive = true
}

output "public_ip" {
  value = module.standard.public_ip
}

output "private_ip" {
  value = module.standard.private_ip
}

output "vnet_id" {
  value = module.standard.vnet_id
}

output "public_subnet_id" {
  value = module.standard.public_subnet_id
}

output "private_subnet_id" {
  value = module.standard.private_subnet_id
}

output "server_nsg_id" {
  value = module.standard.server_nsg_id
}

output "agents_nsg_id" {
  value = module.standard.agents_nsg_id
}

output "agents_managed_identity_id" {
  value = module.standard.agents_managed_identity_id
}

output "email" {
  value = var.primary_email
}

output "default_tags" {
  value = var.azure_tags
}

output "storage_account_name" {
  value = module.standard.storage_account_name
}

output "storage_container_name" {
  value = module.standard.storage_container_name
} 

# Get current client config
data "azurerm_client_config" "current" {}
# output the tenant id
output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
