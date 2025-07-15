variable "aws_access_key" {
  description = "The AWS access key used for deployment"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  description = "The AWS secret key used for deployment"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_region" {
  description = "The AWS Region used for deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^([a-z]{2}-[a-z]{4,}-[\\d]{1})$", var.aws_region))
    error_message = "The aws_region must be a valid Amazon Web Services (AWS) Region name, e.g. us-east-1"
  }
}


# Allow user to specify the preferred availability zone
variable "preferred_availability_zone" {
  description = "Preferred Availability Zone for the deployment"
  type        = string
  default     = ""  # Default is empty, meaning we'll fall back to the first available AZ
}

variable "project_name" {
  description = "The name of the deployment (e.g dev, staging). A short single word"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{3,30}", var.project_name))
    error_message = "The project_name variable can only be one word between 3 and 30 lower-case letters since it is a seed value in multiple object names."
  }
}

variable "server_zone_name" {
  description = "A name given to the deployment zone (e.g. prod, dev, test) - can also be some extra identifier of your choosing"
  type        = string
  default     = "default"

  validation {
    condition     = can(regex("^[a-z0-9A-Z-]{1,30}", var.server_zone_name))
    error_message = "The server_zone_name variable can only be one word between 1 and 30 characters consisting of letters, numbers, dash (-)."
  }
}

variable "domain_name" {
  description = "The dns entry for the master server. The deployment will be accessed via https://{domain_name}"
  type        = string

  validation {
    condition     = can(regex("(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]", var.domain_name))
    error_message = "There are invalid characters in the domain_name - it must be a valid domain name."
  }
}

variable "vpc_subnet_cidr" {
  description = "The subnet CIDR to use for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_subnet_cidr, 0))
    error_message = "The VPC subnet must be valid IPv4 CIDR."
  }
}

variable "swap_size" {
  description = "The amount of swap (in GB) to configure inside the compute instances"
  type        = number
  default     = 4

  validation {
    condition     = var.swap_size >= 1 && var.swap_size <= 8 && floor(var.swap_size) == var.swap_size
    error_message = "Swap size is the amount of disk space to use for each server in GB and must be an integer between 1 and 8."
  }
}

variable "master_instance_type" {
  description = "The instance type for the golden helix server (master)"
  type        = string

  validation {
    condition     = can(regex("^(([a-z-]{1,3})(\\d{1,2})?(\\w{1,4})?)\\.(nano|micro|small|medium|metal|large|(2|3|4|6|8|9|10|12|16|18|24|32|48|56|112)?xlarge)", var.master_instance_type))
    error_message = "Check the master_instance_type variable and ensure it is a valid AWS Instance type (https://aws.amazon.com/ec2/instance-types/)."
  }
}

variable "master_hdd_size_gb" {
  description = "The HDD size in GB to configure for the Golden Helix Server instances"
  type        = number

  validation {
    condition     = can(var.master_hdd_size_gb >= 40)
    error_message = "Master server should have at least a 40 GB HDD to ensure enough space for services."
  }
}

variable "workflow_hdd_size_gb" {
  description = "The secondary workflow drive size in GB to configure for the Golden Helix Server instances"
  type        = number

  validation {
    condition     = can(var.workflow_hdd_size_gb >= 40)
    error_message = "Workflow  drive should have at least a 40 GB HDD to ensure enough space for user data."
  }
}

variable "web_access_cidrs" {
  description = "CIDR notation of the external host allowed to connect to the server over http/https"
  type        = list(string)

  validation {
    condition     = alltrue([for subnet in var.web_access_cidrs : can(cidrhost(subnet, 0))])
    error_message = "One of the subnets provided in the web_access_cidrs variable is invalid."
  }
}

variable "ssh_access_cidrs" {
  description = "CIDR notation of the external host allowed to connect to the server via ssh"
  type        = list(string)

  validation {
    condition     = alltrue([for subnet in var.ssh_access_cidrs : can(cidrhost(subnet, 0))])
    error_message = "One of the subnets provided in the ssh_access_cidrs variable is invalid."
  }
}

variable "ec2_ami_id" {
  description = "The AMI used for the EC2 nodes. Leave empty to use the latest Debian 12 AMI."
  type        = string
  default     = ""  # Default is empty to fall back on the latest Debian 12 AMI
}

variable "ssh_authorized_keys" {
  description = "The SSH Public Keys to be installed on the instance"
  type        = string
  default     = ""

  validation {
    condition     = var.ssh_authorized_keys == "" ? true : can(regex("^(ssh-rsa|ssh-ed25519)", var.ssh_authorized_keys))
    error_message = "The ssh_authorized_keys value is not in the correct format."
  }
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