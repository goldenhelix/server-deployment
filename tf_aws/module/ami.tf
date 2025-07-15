# Look up the latest Debian 12 AMI ID from the AWS Systems Manager Parameter Store

data "aws_ssm_parameter" "debian_12_ami" {
  name = "/aws/service/debian/release/bookworm/latest/amd64"
}
