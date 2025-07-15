# Create IAM role for EC2
resource "aws_iam_role" "agent_role" {
  name = "${var.project_name}-${var.server_zone_name}-agent-role"

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
    Name = "${var.project_name}-${var.server_zone_name}-agent-role"
  }
}

# Attach the AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "agent_ssm_policy" {
  role       = aws_iam_role.agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile
resource "aws_iam_instance_profile" "agent_profile" {
  name = "${var.project_name}-${var.server_zone_name}-agent-profile"
  role = aws_iam_role.agent_role.name
}

# Get as output variable the agent_profile.name so that it can be used in the EC2 instance
output "agents_instance_profile_name" {
  value = aws_iam_instance_profile.agent_profile.name
}