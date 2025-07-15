# Security groups for private instances (see network_private.tf)
resource "aws_security_group" "private_instances" {
  name        = "${var.project_name}-${var.server_zone_name}-private-instances"
  description = "Security group for private subnet instances"
  vpc_id      = aws_vpc.this.id
}
# Allow all traffic from private subnet to server (for NAT functionality)
resource "aws_security_group_rule" "server_private_ingress" {
  description              = "Allow all traffic from private subnet (NAT gateway)"
  security_group_id        = aws_security_group.server.id
  type                     = "ingress"
  from_port               = 0
  to_port                 = 0
  protocol                = "-1"  # All protocols
  source_security_group_id = aws_security_group.private_instances.id
}

# Add ingress rules for private instances from server
resource "aws_security_group_rule" "private_instances_ingress" {
  for_each = {
    ssh = {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    }
    streaming = {
      from_port = 30000
      to_port   = 31000
      protocol  = "tcp"
    }
  }

  description              = "Allow ${each.key} from server"
  security_group_id        = aws_security_group.private_instances.id
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  source_security_group_id = aws_security_group.server.id
}

# Allow private instances to access internet via NAT
resource "aws_security_group_rule" "private_instances_outbound" {
  security_group_id = aws_security_group.private_instances.id
  type             = "egress"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
}

# Output of private_instances security group ID
output "agents_security_group_id" {
  value = aws_security_group.private_instances.id
}