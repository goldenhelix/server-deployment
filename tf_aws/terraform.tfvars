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

## AWS Environment settings
# ssh_authorized_keys = ""  # Uncomment and add your SSH public key
aws_region          = "us-east-1"

## IP ranges (in CIDR notation) that are allowed to access the server
# WARNING: These are example values. Restrict access appropriately in production
web_access_cidrs = ["0.0.0.0/0"]
ssh_access_cidrs = ["0.0.0.0/0"]

## Master Instance Settings
# Choose one of the following instance types:
# master_instance_type = "m6i.xlarge" # 4 cores, 16GB of RAM
master_instance_type = "m6i.2xlarge" # 8 cores, 32GB of RAM
master_hdd_size_gb   = 150
workflow_hdd_size_gb = 600

## General Server settings
# ec2_ami_id = "" # Leave empty to use the latest Debian 13 AMI

# Swap size in GB
swap_size  = 16

## Default tags for all AWS resources, also in dynamic agents
aws_default_tags = {
  Service_name    = "Golden Helix Server"
  Environment     = "production"
}
