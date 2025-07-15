module "standard" {
  source                        = "./module"
  aws_region                    = var.aws_region
  preferred_availability_zone   = var.preferred_availability_zone
  domain_name                   = var.domain_name
  project_name                  = var.project_name
  vpc_subnet_cidr               = var.vpc_subnet_cidr
  aws_default_tags              = var.aws_default_tags

  ## Server settings
  master_instance_type = var.master_instance_type
  master_hdd_size_gb   = var.master_hdd_size_gb
  workflow_hdd_size_gb = var.workflow_hdd_size_gb
  ec2_ami              = var.ec2_ami_id
  swap_size            = var.swap_size
  ssh_authorized_keys  = var.ssh_authorized_keys

  web_access_cidrs           = var.web_access_cidrs
  ssh_access_cidrs           = var.ssh_access_cidrs
  server_zone_name           = var.server_zone_name

  primary_email              = var.primary_email
  registry_user              = var.registry_user
  registry_pass              = var.registry_pass
}
