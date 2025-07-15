data "aws_availability_zones" "available" {
  state = "available"
}

# Determine the availability zone to use
locals {
  az_to_use = var.preferred_availability_zone != "" ? var.preferred_availability_zone : data.aws_availability_zones.available.names[0]
}
