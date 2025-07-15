# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "${var.project_name}-${var.server_zone_name}-rg"
  location = var.location

  tags = var.azure_tags
}

# Output the resource group details
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
} 