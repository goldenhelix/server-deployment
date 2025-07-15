resource "aws_vpc" "this" {
  cidr_block           = var.vpc_subnet_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-gh-vpc"
  }
}

resource "aws_eip" "public" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-gh-eip"
  }
}

# Output VPC ID and Public IP
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_ip" {
  value = aws_eip.public.public_ip
}
