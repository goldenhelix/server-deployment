##
## Public Subnet and Route Table
##

locals {
  gh_vnet_subnet_cidr_mask           = split("/", var.vnet_subnet_cidr)[1]
  gh_server_subnet_cidr_calculation = (8 - (local.gh_vnet_subnet_cidr_mask - 16))
  gh_server_subnet_cidr_size        = local.gh_server_subnet_cidr_calculation < 3 ? 3 : local.gh_server_subnet_cidr_calculation
}

## Public Subnet for the Server (x.x.0.0/24)
resource "azurerm_subnet" "public" {
  name                 = "${var.project_name}-${var.server_zone_name}-public-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.vnet_subnet_cidr, local.gh_server_subnet_cidr_size, 0)]
}

# Create a route table for the public subnet
resource "azurerm_route_table" "public" {
  name                = "${var.project_name}-${var.server_zone_name}-public-rt"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

# Associate the route table with the public subnet
resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public.id
}

# Output the public subnet ID for reference
output "public_subnet_id" {
  value = azurerm_subnet.public.id
} 