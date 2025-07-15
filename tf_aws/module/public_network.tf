##
## Public Subset, Internet Gateway and Route Table
##

locals {
  gh_vpc_subnet_cidr_mask           = split("/", var.vpc_subnet_cidr)[1]
  gh_server_subnet_cidr_calculation = (8 - (local.gh_vpc_subnet_cidr_mask - 16))
  gh_server_subnet_cidr_size        = local.gh_server_subnet_cidr_calculation < 3 ? 3 : local.gh_server_subnet_cidr_calculation
}

## Public Subnet for the Server (x.x.0.0/24)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_subnet_cidr, local.gh_server_subnet_cidr_size, 0)
  availability_zone       = local.az_to_use
  map_public_ip_on_launch = true  # Ensures instances launched here get a public IP

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-gh-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-igw"
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-public-rt"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Output Subnet IDs
output "public_subnet_id" {
  value = aws_subnet.public.id
}
