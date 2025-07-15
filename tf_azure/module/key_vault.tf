# Generate SSH key only if not provided
resource "tls_private_key" "ssh_key" {
  count     = var.ssh_authorized_keys == "" ? 1 : 0
  algorithm = "ED25519"
}

# Store the private key in Azure Key Vault for secure access
resource "azurerm_key_vault" "this" {
  name                = "${var.project_name}${var.server_zone_name}kv"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Purge"
    ]
  }
}

# Store the SSH private key as a secret
resource "azurerm_key_vault_secret" "ssh_private_key" {
  count        = var.ssh_authorized_keys == "" ? 1 : 0
  name         = "ssh-private-key"
  value        = tls_private_key.ssh_key[0].private_key_pem
  key_vault_id = azurerm_key_vault.this.id
}


# Output the key name (either generated or provided)
output "ssh_key_name" {
  value = var.ssh_authorized_keys == "" ? tls_private_key.ssh_key[0].public_key_openssh : var.ssh_authorized_keys
}

# Output the generated public and private keys if generated
output "generated_ssh_public_key" {
  description = "The generated SSH key for the Golden Helix Server"
  value       = var.ssh_authorized_keys == "" ? tls_private_key.ssh_key[0].public_key_openssh : ""
}

output "generated_ssh_private_key" {
  description = "The generated SSH private key for the Golden Helix Server"
  value       = var.ssh_authorized_keys == "" ? tls_private_key.ssh_key[0].private_key_openssh : ""
  sensitive   = true
}

data "azurerm_client_config" "current" {}