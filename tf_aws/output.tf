# Purpose: Define the output variables for the Golden Helix Deployment

output "region" {
  value = var.aws_region
}

output "project_name" {
  value = var.project_name
}

output "zone_name" {
  value = var.server_zone_name
}

output "domain_name" {
  value = var.domain_name
}

output "ssh_key_name" {
  value = module.standard.ssh_key_name
}

output "generated_ssh_public_key" {
  value = module.standard.generated_ssh_public_key
}

output "generated_ssh_private_key" {
  value = module.standard.generated_ssh_private_key
  sensitive = true
}

output "public_ip" {
  value = module.standard.public_ip
}

output "private_ip" {
  value = module.standard.private_ip
}

output "vpc_id" {
  value = module.standard.vpc_id
}

output "public_subnet_id" {
  value = module.standard.public_subnet_id
}

output "private_subnet_id" {
  value = module.standard.private_subnet_id
}

output "server_security_group_id" {
  value = module.standard.server_security_group_id
}

output "agents_security_group_id" {
  value = module.standard.agents_security_group_id
}

output "agents_instance_profile_name" {
  value = module.standard.agents_instance_profile_name
}

output "email" {
  value = var.primary_email
}

output "default_tags" {
  value = var.aws_default_tags
}

output "bucket_name" {
  value = module.standard.bucket_name
}