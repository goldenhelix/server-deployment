resource "aws_security_group" "server" {
  name        = "${var.project_name}-${var.server_zone_name}-ghserver"
  description = "Allow access to servers"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-ghserver-access"
  }
}

# Ingress rule for server: Allow public web access
resource "aws_security_group_rule" "server_web_ingress" {

  for_each = var.web_security_rules

  description              = "Allow Public Web ingress from ${join(",", var.web_access_cidrs)}"
  security_group_id        = aws_security_group.server.id
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = var.web_access_cidrs
}

# Ingress rule for server: Allow public ssh access
resource "aws_security_group_rule" "server_ssh_ingress" {

  for_each = var.ssh_security_rules

  description              = "Allow Public SSH ingress from ${join(",", var.ssh_access_cidrs)}"
  security_group_id        = aws_security_group.server.id
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = var.ssh_access_cidrs
}

# Egress rule for server: Allow outbound traffic
resource "aws_security_group_rule" "server_egress" {
  for_each = var.default_egress

  security_group_id = aws_security_group.server.id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_subnets
}

# Output the security group IDs
output "server_security_group_id" {
  value = aws_security_group.server.id
}
