# Create the Virtual Network (equivalent to VPC)
resource "azurerm_virtual_network" "this" {
  name                = "${var.project_name}-gh-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_subnet_cidr]

  tags = {
    Name = "${var.project_name}-gh-vnet"
  }
}

# Create a public IP for the server
resource "azurerm_public_ip" "server" {
  name                = "${var.project_name}-${var.server_zone_name}-gh-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-gh-pip"
  }
}

# Output Virtual Network ID and Public IP
output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "public_ip" {
  value = azurerm_public_ip.server.ip_address
} 