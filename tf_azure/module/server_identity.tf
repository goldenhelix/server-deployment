# Create a user-assigned managed identity for the server
resource "azurerm_user_assigned_identity" "server" {
  name                = "${var.project_name}-${var.server_zone_name}-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

# Grant permissions to manage VMs and images
resource "azurerm_role_assignment" "vm_contributor" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.server.principal_id
}

# Needed for image creation and management
resource "azurerm_role_assignment" "image_contributor" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor" 
  principal_id         = azurerm_user_assigned_identity.server.principal_id
}

# Add storage blob access for the server
resource "azurerm_role_assignment" "server_storage" {
  scope                = azurerm_storage_account.server.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.server.principal_id
}

# Output the identity details
output "server_identity_id" {
  value = azurerm_user_assigned_identity.server.id
}

output "server_identity_principal_id" {
  value = azurerm_user_assigned_identity.server.principal_id
} 