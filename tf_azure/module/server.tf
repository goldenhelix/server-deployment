# Create the network interface for the server
resource "azurerm_network_interface" "server" {
  name                = "${var.project_name}-${var.server_zone_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.server.id
  }

  tags = var.azure_tags
}


# Associate the NSG with the network interface
resource "azurerm_network_interface_security_group_association" "server" {
  network_interface_id      = azurerm_network_interface.server.id
  network_security_group_id = azurerm_network_security_group.server.id
}

# Create the VM
resource "azurerm_linux_virtual_machine" "server" {
  name                = "${var.project_name}-${var.server_zone_name}-ghserver"
  location            = var.location
  zone                = var.availability_zone
  resource_group_name = azurerm_resource_group.this.name
  size                = var.master_vm_size
  admin_username      = "ghadmin"
  network_interface_ids = [
    azurerm_network_interface.server.id
  ]

  # Use managed identity instead of SystemAssigned
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.server.id]
  }

  admin_ssh_key {
    username   = "ghadmin"
    public_key = tls_private_key.ssh_key[0].public_key_openssh
  }

  os_disk {
    name                 = "${var.project_name}-${var.server_zone_name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.master_os_disk_size_gb
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  custom_data = base64encode(templatefile("${path.module}/../../userdata/server_bootstrap.sh",
    {
      domain_name         = var.domain_name
      swap_size          = var.swap_size
      primary_email      = var.primary_email
      registry_user      = var.registry_user
      registry_pass      = var.registry_pass
      private_subnet_cidr = azurerm_subnet.private.address_prefixes[0]
    }
  ))

  # Azure equivalent of metadata options
  boot_diagnostics {
    storage_account_uri = null  # Uses managed storage account
  }

  tags = merge(var.azure_tags, {
    NightlyBackup      = "true"
  })
}

# Create the data disk
resource "azurerm_managed_disk" "workflow_data" {
  name                 = "${var.project_name}-${var.server_zone_name}-workflow-disk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "PremiumV2_LRS" # PremiumV2 is the highest IOPS disk type and arbitrary size
  create_option        = "Empty"
  disk_size_gb         = var.workflow_data_disk_size_gb
  zone                 = var.availability_zone
  
  #tier                 = "P30"  # Higher IOPS

  tags = merge(var.azure_tags, {
    DailyBackup = "true"
  })
}

# Attach the data disk
resource "azurerm_virtual_machine_data_disk_attachment" "workflow_data" {
  managed_disk_id    = azurerm_managed_disk.workflow_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.server.id
  lun                = "10"
  caching            = "None"
}

# Output the private IP
output "private_ip" {
  value = azurerm_linux_virtual_machine.server.private_ip_address
} 