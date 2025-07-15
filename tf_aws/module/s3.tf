
resource "aws_s3_bucket" "server_bucket" {
  bucket = "${var.project_name}-${var.server_zone_name}-gh-bucket"

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-gh-bucket"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "server_bucket_lifecycle" {
  bucket = aws_s3_bucket.server_bucket.id

  rule {
    id     = "Move to Intelligent-Tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}


resource "aws_iam_policy" "s3_access_policy" {
  name = "${var.project_name}-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "${aws_s3_bucket.server_bucket.arn}",
          "${aws_s3_bucket.server_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attachment_server" {
  role       = aws_iam_role.server_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_attachment_agent" {
  role       = aws_iam_role.agent_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Output bucket name
output "bucket_name" {
  value = aws_s3_bucket.server_bucket.bucket
}