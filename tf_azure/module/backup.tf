# Data Protection backup vault
resource "azurerm_data_protection_backup_vault" "vault" {
  name                = "${var.project_name}-${var.server_zone_name}-vault"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  # Required for disk backup
  datastore_type = "VaultStore"         # Hot storage, cheapest for 7-day retention
  redundancy     = "LocallyRedundant"   # Or "ZoneRedundant"

  # Disable soft delete to allow clean destruction
  soft_delete = "Off"

  identity { type = "SystemAssigned" }  # Needed for RBAC

  tags = var.azure_tags
}

# Daily backup policy (7-day retention)
resource "azurerm_data_protection_backup_policy_disk" "daily" {
  name     = "${var.project_name}-${var.server_zone_name}-daily-backup"
  vault_id = azurerm_data_protection_backup_vault.vault.id
  time_zone = "UTC"

  # ISO-8601 repeating interval: once per day at 23:00 UTC
  # Start date can be any past date; keep it constant for idempotency.
  backup_repeating_time_intervals = ["R/2025-01-01T23:00:00Z/P1D"]

  # Retain the last 7 recovery points
  default_retention_duration = "P7D"
}

# RBAC – let the vault read the disk & create snapshots
# a) Vault needs Disk Backup Reader on the source disk
resource "azurerm_role_assignment" "disk_backup_reader" {
  scope                = azurerm_managed_disk.workflow_data.id
  role_definition_name = "Disk Backup Reader"     # Built-in role
  principal_id         = azurerm_data_protection_backup_vault.vault.identity[0].principal_id
}

# a2) Vault needs Disk Backup Reader on the OS disk
resource "azurerm_role_assignment" "os_disk_backup_reader" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.this.name}/providers/Microsoft.Compute/disks/${var.project_name}-${var.server_zone_name}-os-disk"
  role_definition_name = "Disk Backup Reader"     # Built-in role
  principal_id         = azurerm_data_protection_backup_vault.vault.identity[0].principal_id

  depends_on = [
    azurerm_linux_virtual_machine.server
  ]
}

# b) Vault needs Disk Snapshot Contributor on the snapshot RG
resource "azurerm_role_assignment" "disk_snapshot_contributor" {
  scope                = azurerm_resource_group.this.id        # Snapshots live here
  role_definition_name = "Disk Snapshot Contributor"
  principal_id         = azurerm_data_protection_backup_vault.vault.identity[0].principal_id
}

# Protect the workflows disk
resource "azurerm_data_protection_backup_instance_disk" "workflow_data" {
  name                         = "${var.project_name}-${var.server_zone_name}-workflowdata"
  location                     = azurerm_resource_group.this.location
  vault_id                     = azurerm_data_protection_backup_vault.vault.id

  disk_id                      = azurerm_managed_disk.workflow_data.id
  snapshot_resource_group_name = azurerm_resource_group.this.name
  backup_policy_id             = azurerm_data_protection_backup_policy_disk.daily.id

  depends_on = [
    azurerm_role_assignment.disk_backup_reader,
    azurerm_role_assignment.disk_snapshot_contributor
  ]
}

# Protect the OS disk
resource "azurerm_data_protection_backup_instance_disk" "os_disk" {
  name                         = "${var.project_name}-${var.server_zone_name}-osdisk"
  location                     = azurerm_resource_group.this.location
  vault_id                     = azurerm_data_protection_backup_vault.vault.id

  disk_id                      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.this.name}/providers/Microsoft.Compute/disks/${var.project_name}-${var.server_zone_name}-os-disk"
  snapshot_resource_group_name = azurerm_resource_group.this.name
  backup_policy_id             = azurerm_data_protection_backup_policy_disk.daily.id

  depends_on = [
    azurerm_role_assignment.os_disk_backup_reader,
    azurerm_role_assignment.disk_snapshot_contributor
  ]
}