
# Attach the AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "server_ssm_policy" {
  role       = aws_iam_role.server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
