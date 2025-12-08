# Create Storage Account
resource "azurerm_storage_account" "server" {
  name                     = "${var.project_name}${var.server_zone_name}st"  # must be globally unique, no hyphens
  resource_group_name      = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  account_tier            = "Standard" # Standard account needed for lifecycle tiering by last access time
  account_replication_type = "LRS"
  is_hns_enabled          = true
  nfsv3_enabled           = true
  account_kind            = "StorageV2"
  
  # NFS 3.0 requires HTTPS-only to be disabled
  # NFS 3.0 protocol is automatically enabled when hierarchical namespace (is_hns_enabled) is true
  https_traffic_only_enabled = false

  blob_properties {
    last_access_time_enabled = true
  }

  # Network rules to allow VNet access for NFS 3.0 protocol
  # NFS 3.0 requires network access from the VNet
  network_rules {
    # Allow Azure services (including Azure Portal) to bypass network rules
    # This enables browsing in Azure Portal even with restricted network access
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = var.storage_allowed_ip_addresses
    virtual_network_subnet_ids = [
      azurerm_subnet.public.id,
      azurerm_subnet.private.id
    ]
  }
}

resource "azurerm_storage_management_policy" "intelligent_tiering_like" {
  storage_account_id = azurerm_storage_account.server.id

  rule {
    name    = "${var.project_name}-${var.server_zone_name}-intelligent-tiering"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = [""] # apply to all blobs; add prefixes if you want to scope it
    }

    actions {
      base_blob {
        # 30 days since last access -> Cool
        tier_to_cool_after_days_since_last_access_time_greater_than = 30

        # 90 days since last access -> Cold (online tier; higher latency/lower price than Cool)
        tier_to_cold_after_days_since_last_access_time_greater_than = 90

        # Do NOT transition to Archive
        # tier_to_archive_after_days_since_last_access_time_greater_than = null

        # If a Cool blob is read, auto-bounce back to Hot
        auto_tier_to_hot_from_cool_enabled = true
      }
    }
  }
}

# Create Storage Container
# For NFS 3.0-enabled storage accounts, containers are automatically exported and can be mounted via NFS
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

# Output NFS mount endpoint for NFS3 protocol access
output "storage_nfs_endpoint" {
  description = "NFS3 mount endpoint for the blob storage container"
  value       = "${azurerm_storage_account.server.name}.blob.core.windows.net:/${azurerm_storage_account.server.name}/${azurerm_storage_container.server.name}"
}
