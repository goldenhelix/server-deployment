# Create a user-assigned managed identity for agents
resource "azurerm_user_assigned_identity" "agents" {
  name                = "${var.project_name}-${var.server_zone_name}-agent-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

# Grant agents access to the storage container
resource "azurerm_role_assignment" "agent_storage" {
  scope                = azurerm_storage_account.server.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.agents.principal_id
}

# Output the agent identity ID for use in agent VM creation
output "agents_managed_identity_id" {
  value = azurerm_user_assigned_identity.agents.id
}

output "agents_managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.agents.principal_id
} 