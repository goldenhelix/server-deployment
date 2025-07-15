# Core settings
variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "availability_zone" {
  description = "The Availability Zone to deploy resources into (e.g., '1', '2', '3'). Required if use_premium_v2 is true."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "server_zone_name" {
  description = "Zone name for the resources (e.g., prod, dev, test)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the server"
  type        = string
}

variable "vnet_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.0.0/16"
}

# Server configuration
variable "master_vm_size" {
  description = "Azure VM size for the server"
  type        = string
}

variable "master_os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
}

variable "workflow_data_disk_size_gb" {
  description = "Size of the workflow data disk in GB"
  type        = number
}

variable "vm_image" {
  description = "VM image details"
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
}

# Access control
variable "web_access_cidrs" {
  description = "List of CIDR blocks allowed to access web ports"
  type        = list(string)
}

variable "ssh_access_cidrs" {
  description = "List of CIDR blocks allowed to access SSH"
  type        = list(string)
}

variable "ssh_authorized_keys" {
  description = "SSH public keys to add to authorized_keys file"
  type        = string
  default     = ""
}

# Authentication and credentials
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

# Resource tagging
variable "azure_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "web_security_rules" {
  description = "A map of objects of web security rules to apply to the Golden Helix Server"
  type = map(object({
    from_port = number
    to_port   = number
    protocol  = string
  }))

  default = {
    https = {
      from_port = 443
      to_port   = 443
      protocol  = "Tcp"
    }
    https_udp = {
      from_port = 443
      to_port   = 443
      protocol  = "Udp"
    }
    admin_console_tcp = {
      from_port = 4433
      to_port   = 4433
      protocol  = "Tcp"
    }
    admin_console_udp = {
      from_port = 4433
      to_port   = 4433
      protocol  = "Udp"
    }
    http = {
      from_port = 80
      to_port   = 80
      protocol  = "Tcp"
    }
  }
}


variable "ssh_security_rules" {
  description = "A map of objects of SSH security rules to apply to the Golden Helix Server"
  type = map(object({
    from_port = number
    to_port   = number
    protocol  = string
  }))

  default = {
    ssh = {
      from_port = 22
      to_port   = 22
      protocol  = "Tcp"
      cidr_subnets = ["0.0.0.0/0"]
    }
  }
}

variable "default_egress" {
  description = "Default egress security rule for all security groups"
  type = map(object({
    from_port    = number
    to_port      = number
    protocol     = string
    cidr_subnets = list(string)
  }))

  default = {
    all = {
      from_port    = 0
      to_port      = 0
      protocol     = "*"
      cidr_subnets = ["0.0.0.0/0"]
    }
  }
}
