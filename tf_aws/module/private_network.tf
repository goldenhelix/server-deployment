##
## Private Subset, NAT and Route Table
##

## Will create private subnet x.x.1.0/24 (assuming a VPC Subnet CIDR between x.x.0.0/16 and x.x.0.0/21)
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_subnet_cidr, local.gh_server_subnet_cidr_size, 1)
  map_public_ip_on_launch = false # Instances launched here will not get a public IP
  availability_zone       = local.az_to_use

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-gh-private-subnet"
  }
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

# We use the Server as a NAT for the private subnet
# We don't expect much outbound traffic, this saves the complexity of a NAT Gateway

# We will use the Server's network interface as the route target for the private subnet
data "aws_network_interface" "server" {
  depends_on = [aws_instance.server]
  
  filter {
    name   = "attachment.instance-id"
    values = [aws_instance.server.id]
  }
}

# Update private subnet route table to use the server's network interface
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = data.aws_network_interface.server.id
  }

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-private-rt"
  }
}

# Associate private route table with private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

##
## VPC Endpoint: S3 (Gateway)
##
## Allows private subnet instances to reach S3 without traversing NAT/IGW.
## This endpoint is associated with the private route table used by the private subnet
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.aws_region}.s3"

  # Gateway endpoints are attached to route tables (not subnets)
  # Attach to both private + public route tables so instances in either subnet
  # (including the server in the public subnet) use the S3 endpoint routes.
  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id
  ]

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-s3-gateway-endpoint"
  }
}