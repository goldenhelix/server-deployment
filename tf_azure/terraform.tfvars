## Deployment vars

# Provided by Golden Helix team or your IT department
domain_name    = "your_institution.varseq.com"

# Primary Golden Helix user account
# Configured as server admin contact
primary_email  = "admin@your_institution.com"

# Provided by Golden Helix: registry.goldenhelix.com username and password
registry_user    = "your_institution"
registry_pass    = "your_registry_password"

# Project name for the resources
project_name   = "your_institution"
# Zone name for the resources, e.g. "prod", "dev", "test"
server_zone_name = "prod"

## Azure Environment settings
# ssh_authorized_keys = ""  # Uncomment and add your SSH public key
location            = "eastus"  # Azure region
availability_zone   = "1"
subscription_id     = "your_subscription_id"

## IP ranges (in CIDR notation) that are allowed to access the server
# WARNING: These are example values. Restrict access appropriately in production
web_access_cidrs = ["0.0.0.0/0"]
ssh_access_cidrs = ["0.0.0.0/0"]

## Master Instance Settings
# Choose one of the following VM sizes:
# Standard_D4s_v5 (4 cores, 16GB RAM) or Standard_D8s_v5 (8 cores, 32GB RAM)
master_vm_size     = "Standard_D8s_v5"  # 8 cores, 32GB RAM
master_os_disk_size_gb    = 150
workflow_data_disk_size_gb = 600

## General Server settings
# vm_image = {} # Leave empty to use the latest Debian 12 image

# Swap size in GB
swap_size  = 16

## Default tags for all Azure resources
azure_tags = {
  Service_name    = "Golden Helix Server"
  Environment     = "production"
} 