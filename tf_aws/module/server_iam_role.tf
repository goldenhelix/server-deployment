# Create IAM role for EC2
resource "aws_iam_role" "server_role" {
  name = "${var.project_name}-${var.server_zone_name}-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-server-role"
  }
}

# Create instance profile
resource "aws_iam_instance_profile" "server_profile" {
  name = "${var.project_name}-${var.server_zone_name}-server-profile"
  role = aws_iam_role.server_role.name
}