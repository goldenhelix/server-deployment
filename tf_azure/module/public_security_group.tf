# Create Network Security Group for the server
resource "azurerm_network_security_group" "server" {
  name                = "${var.project_name}-${var.server_zone_name}-ghserver"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-ghserver-access"
  }
}

# Web access rules
resource "azurerm_network_security_rule" "server_web_ingress" {
  for_each = var.web_security_rules

  name                        = "web-${each.key}"
  priority                    = 1000 + index(keys(var.web_security_rules), each.key)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = each.value.protocol
  source_port_range          = "*"
  destination_port_range     = "${each.value.from_port}-${each.value.to_port}"
  source_address_prefixes    = var.web_access_cidrs
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.server.name
  description                = "Allow Public Web ingress from ${join(",", var.web_access_cidrs)}"
}

# SSH access rules
resource "azurerm_network_security_rule" "server_ssh_ingress" {
  for_each = var.ssh_security_rules

  name                        = "ssh-${each.key}"
  priority                    = 2000 + index(keys(var.ssh_security_rules), each.key)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = each.value.protocol
  source_port_range          = "*"
  destination_port_range     = "${each.value.from_port}-${each.value.to_port}"
  source_address_prefixes    = var.ssh_access_cidrs
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.server.name
  description                = "Allow Public SSH ingress from ${join(",", var.ssh_access_cidrs)}"
}

# Egress rules
resource "azurerm_network_security_rule" "server_egress" {
  for_each = var.default_egress

  name                        = "egress-${each.key}"
  priority                    = 3000 + index(keys(var.default_egress), each.key)
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = each.value.protocol
  source_port_range          = "*"
  destination_port_range     = "${each.value.from_port}-${each.value.to_port}"
  source_address_prefix      = "*"
  destination_address_prefixes = each.value.cidr_subnets
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.server.name
}

# Output the NSG ID
output "server_nsg_id" {
  value = azurerm_network_security_group.server.id
} 