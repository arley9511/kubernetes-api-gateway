locals {
  ec2 = flatten([
    for instance in var.ec2: {
      name =  instance.name
      ami =  instance.ami
      instance_type =  instance.instance_type
      key_name = instance.key_name
      key_output = instance.key_output
      monitoring = instance.monitoring
      vpc_security_group_ids = [for sg in var.security_groups: sg.id if contains(instance.vpc_security_group_ids, sg.name)]
      subnet_id = [for subnet in var.subnets: subnet.subnet_id if subnet.name == instance.subnet_id][0]
      tags = instance.tags
      user_data_path = instance.user_data_path
    }
  ])
}

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  for_each = {
    for item in local.ec2: item.name => item
  }

  key_name   = each.value.key_name
  public_key = tls_private_key.main.public_key_openssh

  provisioner "local-exec" {
    # Create ".pem" in the project folder
    command = "echo '${tls_private_key.main.private_key_pem}' > ${each.value.key_output}"
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  depends_on = [aws_key_pair.main]

  for_each = {
    for item in local.ec2: item.name => item
  }

  name = each.value.name

  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  key_name               = each.value.key_name
  monitoring             = each.value.monitoring
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = each.value.subnet_id
  tags                   = each.value.tags

  user_data = file(each.value.user_data_path)
}
