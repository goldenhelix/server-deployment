##
## Private Subnet and Route Table
##

## Will create private subnet x.x.1.0/24 (assuming a VPC Subnet CIDR between x.x.0.0/16 and x.x.0.0/21)
resource "azurerm_subnet" "private" {
  name                 = "${var.project_name}-${var.server_zone_name}-private-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.vnet_subnet_cidr, local.gh_server_subnet_cidr_size, 1)]
}

# Note in Azure, we allow the private subnet to access the internet by default
# This could be adjusted to route through the server if desired to have a bit more control
resource "azurerm_route_table" "private" {
  name                = "${var.project_name}-${var.server_zone_name}-private-rt"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

# Associate the route table with the private subnet
resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private.id
}


# Output the private subnet ID for reference
output "private_subnet_id" {
  value = azurerm_subnet.private.id
}
