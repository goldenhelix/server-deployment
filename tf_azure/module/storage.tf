# Create Storage Account
resource "azurerm_storage_account" "server" {
  name                     = "${var.project_name}${var.server_zone_name}st"  # must be globally unique, no hyphens
  resource_group_name      = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  account_tier            = "Standard" # Standard account needed for lifecycle tiering by last access time
  account_replication_type = "LRS"
  is_hns_enabled          = true
  account_kind            = "StorageV2"

  blob_properties {
    last_access_time_enabled = true
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