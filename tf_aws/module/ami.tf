# Look up the latest Debian 12 AMI ID from the AWS Systems Manager Parameter Store

data "aws_ssm_parameter" "debian_13_ami" {
  name = "/aws/service/debian/release/trixie/latest/amd64"
}
