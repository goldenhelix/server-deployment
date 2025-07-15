# Create Storage Account
resource "azurerm_storage_account" "server" {
  name                     = "${var.project_name}${var.server_zone_name}st"  # must be globally unique, no hyphens
  resource_group_name      = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  account_tier            = "Premium"
  account_replication_type = "LRS"
  is_hns_enabled          = true
  account_kind            = "BlockBlobStorage"
}

# Create File Share
resource "azurerm_storage_container" "server" {
  name                 = "${var.project_name}-${var.server_zone_name}-container"
  storage_account_id   = azurerm_storage_account.server.id
  container_access_type = "private"
}

# Output the storage details
output "storage_account_name" {
  value = azurerm_storage_account.server.name
}

output "storage_container_name" {
  value = azurerm_storage_container.server.name
} 