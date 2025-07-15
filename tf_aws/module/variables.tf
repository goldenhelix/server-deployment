variable "project_name" {
  description = "The name of the deployment (e.g dev, staging). A short single word"
  type        = string
}

variable "domain_name" {
  description = "The dns entry for the master server. The deployment will be accessed via https://{domain_name}"
  type        = string
}

variable "vpc_subnet_cidr" {
  description = "The subnet CIDR to use for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "master_instance_type" {
  description = "The instance type for the golden helix server (master)"
  type        = string
  default     = "t3.small"
}

variable "master_hdd_size_gb" {
  description = "The HDD size in GB to configure for the Golden Helix Server instances"
  type        = number
}

variable "workflow_hdd_size_gb" {
  description = "The workflow drive size in GB to configure for the Golden Helix Server instances"
  type        = number
}

variable "web_access_cidrs" {
  description = "CIDR notation of the external host allowed to connect to the server over http/https"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_access_cidrs" {
  description = "CIDR notation of the external host allowed to connect to the server over ssh"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "aws_region" {
  description = "The AWS region for the deployment. (e.g us-east-1)"
  type        = string
}

variable "preferred_availability_zone" {
  description = "Preferred Availability Zone for the deployment"
  type        = string
  default     = ""
}

variable "ec2_ami" {
  description = "The AMI used for the EC2 nodes. Recommended Ubuntu 20.04 LTS."
  type        = string
}

variable "swap_size" {
  description = "The amount of swap (in GB) to configure inside the compute instances"
  type        = number
}

variable "server_zone_name" {
  description = "A name given to the deployment Zone"
  type        = string
  default     = "default"
}

variable "anywhere" {
  description = "Anywhere route subnet"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.anywhere, 0))
    error_message = "Anywhere variable must be valid IPv4 CIDR - usually 0.0.0.0/0 for all default routes and default Security Group access."
  }
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
      protocol  = "tcp"
    }
    https_udp = {
      from_port = 443
      to_port   = 443
      protocol  = "udp"
    }
    admin_console_tcp = {
      from_port = 4433
      to_port   = 4433
      protocol  = "tcp"
    }
    admin_console_udp = {
      from_port = 4433
      to_port   = 4433
      protocol  = "udp"
    }
    http = {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
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
      protocol  = "tcp"
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
      protocol     = "-1"
      cidr_subnets = ["0.0.0.0/0"]
    }
  }
}

variable "ssh_authorized_keys" {
  description = "The SSH Public Keys to be installed on the OCI compute instance"
  type        = string
}

variable "aws_default_tags" {
  description = "Default tags to apply to all AWS resources for this deployment"
  type        = map(any)
  default     = {}
}

variable "primary_email" {
  description = "The primary email address for the Golden Helix Server"
  type        = string
}

variable "registry_user" {
  description = "The registry.goldenhelix.com username for the Golden Helix Server"
  type        = string
}

variable "registry_pass" {
  description = "The registry.goldenhelix.com password for the Golden Helix Server"
  type        = string
}