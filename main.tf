data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "random_id" "name" {
  byte_length = 4
}

resource "aws_key_pair" "awskey" {
  key_name   = "awskwy-${random_id.name.hex}"
  public_key = tls_private_key.awskey.public_key_openssh
}

data "template_file" "bastion" {
  count    = var.bastion_count
  template = file("${path.module}/configs/bastion.tpl")
  vars = {
    vault_version       = var.vault_version
    secrets_manager_arn = var.secrets_manager_arn
    aws_region          = var.aws_region
    vault_lb_dns_name   = var.vault_lb_dns_name
  }
}

data "template_file" "telemetry" {
  count    = var.telemetry_count
  template = file("${path.module}/configs/telemetry.tpl")
  vars = {
    vault_version       = var.vault_version
    secrets_manager_arn = var.secrets_manager_arn
    aws_region          = var.aws_region
    vault_lb_dns_name   = var.vault_lb_dns_name
  }
}

resource "aws_instance" "bastion" {
  count                   = var.bastion_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.awskey.key_name
  vpc_security_group_ids  = [aws_security_group.bastion.id]
  subnet_id               = sort(data.aws_subnet_ids.vault.ids)[0]
  iam_instance_profile    = var.aws_iam_instance_profile
  associate_public_ip_address = true

  tags = {
    Name        = var.resource_name_prefix
    Description = "Bastion Node"
  }

  user_data = element(data.template_file.bastion.*.rendered, count.index)

}

resource "aws_instance" "telemetry" {
  count                   = var.telemetry_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.awskey.key_name
  vpc_security_group_ids  = [aws_security_group.bastion.id]
  subnet_id               = sort(data.aws_subnet_ids.vault.ids)[0]
  iam_instance_profile    = var.aws_iam_instance_profile
  associate_public_ip_address = true

  tags = {
    Name        = var.resource_name_prefix
    Description = "Telemetry Node"
  }

  user_data = element(data.template_file.telemetry.*.rendered, count.index)

}
