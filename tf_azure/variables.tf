variable "domain_name" {
  description = "Domain name for the server"
  type        = string
}

variable "primary_email" {
  description = "Primary admin contact email"
  type        = string
}

variable "registry_user" {
  description = "Golden Helix registry username"
  type        = string
}

variable "registry_pass" {
  description = "Golden Helix registry password"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "server_zone_name" {
  description = "Zone name for the resources (e.g., prod, dev, test)"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "availability_zone" {
  description = "The Availability Zone to deploy resources into (e.g., '1', '2', '3'). Required if use_premium_v2 is true."
  type        = string
  default     = null
}

variable "subscription_id" {
  description = "The Subscription ID for Azure"
  type        = string
}

variable "ssh_authorized_keys" {
  description = "SSH public keys to add to authorized_keys file"
  type        = string
  default     = ""
}

variable "vnet_subnet_cidr" {
  description = "The subnet CIDR to use for the VNet"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_subnet_cidr, 0))
    error_message = "The VNet subnet must be valid IPv4 CIDR."
  }
}

variable "web_access_cidrs" {
  description = "List of CIDR blocks allowed to access web ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for subnet in var.web_access_cidrs : can(cidrhost(subnet, 0))])
    error_message = "One of the subnets provided in the web_access_cidrs variable is invalid."
  }
}

variable "ssh_access_cidrs" {
  description = "List of CIDR blocks allowed to access SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for subnet in var.ssh_access_cidrs : can(cidrhost(subnet, 0))])
    error_message = "One of the subnets provided in the ssh_access_cidrs variable is invalid."
  }
}

variable "master_vm_size" {
  description = "Azure VM size for the master instance"
  type        = string
  default     = "Standard_D8s_v5"
}

variable "master_os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 100
}

variable "workflow_data_disk_size_gb" {
  description = "Size of the workflow data disk in GB"
  type        = number
  default     = 600
}

variable "vm_image" {
  description = "Custom VM image details. Leave empty to use latest Debian 12"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12"
    version   = "latest"
  }
}

variable "swap_size" {
  description = "Swap size in GB"
  type        = number
  default     = 4
}

variable "azure_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 