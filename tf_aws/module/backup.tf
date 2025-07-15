# Automatic EBS snapshots
resource "aws_dlm_lifecycle_policy" "ebs_backup" {
  description        = "EBS backup policy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state             = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "${var.project_name}-${var.server_zone_name}-daily-ebs-snapshots"
      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times        = ["23:45"]
      }
      retain_rule {
        count = 7  # Keep last 7 daily backups
      }
      tags_to_add = merge(
        var.aws_default_tags,
        {
          SnapshotCreator = "DLM"
        }
      )
    }
    target_tags = {
      DailyBackup = "true"
    }
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "${var.project_name}-${var.server_zone_name}-dlm-lifecycle-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dlm_lifecycle_policy_attachment" {
  role       = aws_iam_role.dlm_lifecycle_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}