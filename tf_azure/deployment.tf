module "standard" {
  source                        = "./module"
  # Core settings
  location         = var.location
  availability_zone = var.availability_zone
  domain_name      = var.domain_name
  project_name     = var.project_name
  server_zone_name = var.server_zone_name

  # Server settings
  master_vm_size             = var.master_vm_size
  master_os_disk_size_gb     = var.master_os_disk_size_gb
  workflow_data_disk_size_gb = var.workflow_data_disk_size_gb
  vm_image                   = var.vm_image
  swap_size                  = var.swap_size
  ssh_authorized_keys        = var.ssh_authorized_keys

  # Access control
  web_access_cidrs = var.web_access_cidrs
  ssh_access_cidrs = var.ssh_access_cidrs

  # Authentication and credentials
  primary_email  = var.primary_email
  registry_user  = var.registry_user
  registry_pass  = var.registry_pass

  # Resource tagging
  azure_tags     = var.azure_tags
}
