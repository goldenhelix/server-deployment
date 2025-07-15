# Network Security Group for private instances
resource "azurerm_network_security_group" "private_nsg" {
  name                = "${var.project_name}-${var.server_zone_name}-private-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

# Outbound rule to allow internet access
resource "azurerm_network_security_rule" "allow_outbound_internet" {
  name                        = "AllowOutboundInternet"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_subnet.private.address_prefixes[0]
  destination_address_prefix  = "Internet"
  network_security_group_name = azurerm_network_security_group.private_nsg.name
  resource_group_name         = azurerm_resource_group.this.name
}

# Add ingress rules for private instances from server
resource "azurerm_network_security_rule" "private_nsg_ingress" {
  for_each = {
    ssh = {
      from_port = 22
      to_port   = 22
      protocol  = "Tcp"
    }
    streaming = {
      from_port = 30000
      to_port   = 31000
      protocol  = "Tcp"
    }
  }

  name                         = "server-to-private-${each.key}"
  priority                     = 200 + index(keys({ssh = {}, streaming = {}}), each.key)
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = each.value.protocol
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_range      = "${each.value.from_port}-${each.value.to_port}"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
  source_application_security_group_ids = []
  description                 = "Allow ${each.key} from server"
}

resource "azurerm_subnet_network_security_group_association" "private_nsg_assoc" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# Output of private_nsg NSG ID
output "agents_nsg_id" {
  value = azurerm_network_security_group.private_nsg.id
} 