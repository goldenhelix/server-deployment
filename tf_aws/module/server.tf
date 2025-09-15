resource "aws_instance" "server" {
  ami                         = var.ec2_ami != "" ? var.ec2_ami : data.aws_ssm_parameter.debian_13_ami.value
  instance_type               = var.master_instance_type
  vpc_security_group_ids      = [aws_security_group.server.id]
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.ssh_keys.key_name
  iam_instance_profile        = aws_iam_instance_profile.server_profile.name
  source_dest_check           = false  # Required for NAT functionality
  associate_public_ip_address = true

  # Enable detailed monitoring
  monitoring = true

  # (OPTIONAL) Enable termination protection
  # disable_api_termination = true

  root_block_device {
    volume_size = var.master_hdd_size_gb
    tags = {
      Name        = "${var.project_name}-${var.server_zone_name}-root-volume"
      DailyBackup = "true"
    }
  }

  user_data = templatefile("${path.module}/../../userdata/server_bootstrap.sh",
    {
      # Variables for server_variables.tfvars written on server
      domain_name       = var.domain_name
      aws_region        = var.aws_region
      swap_size         = var.swap_size
      primary_email     = var.primary_email
      registry_user     = var.registry_user
      registry_pass     = var.registry_pass
      private_subnet_cidr = aws_subnet.private.cidr_block  
    }
  )

  # Make sure IMDSv2 is configured correctly for SSM
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = null
  }

  tags = {
    Name = "${var.project_name}-${var.server_zone_name}-ghserver"
    # Enable nightly backups of EBS volumes
    NightlyBackup = "true"
  }
}

# Secondary EBS volume for workflow data
resource "aws_ebs_volume" "workflow_data" {
  availability_zone = aws_instance.server.availability_zone
  size             = var.workflow_hdd_size_gb
  type             = "gp3"
  iops             = 16000
  throughput       = 1000

  tags = {
    Name        = "${var.project_name}-${var.server_zone_name}-workflow-volume"
    DailyBackup = "true"
  }
}

resource "aws_volume_attachment" "workflow_data_att" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.workflow_data.id
  instance_id = aws_instance.server.id
}

# Associate the EIP with the EC2 instance
resource "aws_eip_association" "server_eip" {
  instance_id   = aws_instance.server.id
  allocation_id = aws_eip.public.id
}

# Output
output "private_ip" {
  value = aws_instance.server.private_ip
}