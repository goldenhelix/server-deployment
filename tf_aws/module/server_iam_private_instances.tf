
# Get current AWS account ID
data "aws_caller_identity" "current" {}

# EC2 and AMI management policy
resource "aws_iam_policy" "private_instance_tf_policy" {
  name        = "${var.project_name}-${var.server_zone_name}-private-instance-tf-executor-policy"
  description = "Policy for executing Terraform EC2 and AMI operations to manage private instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # IAM self-inspection permissions
      {
        Effect = "Allow"
        Action = [
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.server_zone_name}-server-role"
        ]
      },
      # Global actions that can't be tag or subnet restricted
      {
        Effect = "Allow"
        Action = [
          # EC2 Describe actions
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstanceCreditSpecifications",
           
          # AMI Management
          "ec2:CreateImage",
          "ec2:CreateSnapshot",
          "ec2:RegisterImage",

          # Tag Management
          "ec2:CreateTags",
          "ec2:DescribeTags",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": var.aws_region,
          }
        }
      },
      # Actions that can be tag and subnet restricted
      {
        Effect = "Allow"
        Action = [
          # EC2 Describe actions
          "ec2:DescribeInstanceAttribute",
           
          # AMI Management
          "ec2:DeregisterImage",
          "ec2:DeleteSnapshot",

          # Tag Management
          "ec2:DeleteTags",

          # General
          "ec2:DescribeVpcs",
        ]
        Resource = "*"
        Condition = {
            StringEquals = merge(
            {
              "aws:RequestedRegion": var.aws_region,
            },
            { for k, v in var.aws_default_tags : "aws:ResourceTag/${k}" => v }
          )
        }
      },
      # Instance management actions that can be subnet and tag restricted
      {
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:MonitorInstances",
        ],
        "Resource": [
            "arn:aws:ec2:*:*:subnet/${aws_subnet.private.id}",
            "arn:aws:ec2:*:*:network-interface/*",
            "arn:aws:ec2:*:*:instance/*",
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*::image/ami-*",
            "arn:aws:ec2:*:*:key-pair/*",
            "arn:aws:ec2:*:*:security-group/*"
        ],
        Condition = {
          StringEquals = {
            for k, v in var.aws_default_tags : "aws:ResourceTag/${k}" => v
          }
        }
      },
      # Instance creation actions that can be subnet restricted
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
        ],
        "Resource": [
            "arn:aws:ec2:*:*:subnet/${aws_subnet.private.id}",
            "arn:aws:ec2:*:*:network-interface/*",
            "arn:aws:ec2:*:*:instance/*",
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*::image/ami-*",
            "arn:aws:ec2:*:*:key-pair/*",
            "arn:aws:ec2:*:*:security-group/*"
        ]
      },
      # Allow passing IAM roles to instances
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.server_zone_name}-agent-role"
        ]
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-${var.server_zone_name}-private-instance-tf-executor-policy"
    Project = var.project_name
  }
}

# Attach the EC2 and AMI management policy
resource "aws_iam_role_policy_attachment" "ec2_ami_management_attachment" {
  role       = aws_iam_role.server_role.name
  policy_arn = aws_iam_policy.private_instance_tf_policy.arn
}
