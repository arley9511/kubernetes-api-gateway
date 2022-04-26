locals {
  vpc = flatten([
    for vpc in var.vpc: {
      cidr_block = vpc.cidr_block
      instance_tenancy = vpc.instance_tenancy
      enable_dns_support = vpc.enable_dns_support
      enable_dns_hostnames = vpc.enable_dns_hostnames
      name = vpc.name
    }
  ])
  security_groups = flatten([
    for vpc in var.vpc: [
      for security_group in vpc.security_groups: {
        vpc_id = vpc.name
        name = security_group.name
        ingress = security_group.ingress
        egress = security_group.egress
      }
    ]
  ])
}

resource "aws_vpc" "main" {
  for_each = {
  for item in local.vpc: item.name => item
  }

  cidr_block = each.value.cidr_block
  instance_tenancy = each.value.instance_tenancy
  enable_dns_support = each.value.enable_dns_support
  enable_dns_hostnames = each.value.enable_dns_hostnames

  tags = {
    Name = each.value.name
  }
}

resource "aws_internet_gateway" "main" {
  depends_on = [
    aws_vpc.main
  ]

  for_each = {
  for item in local.vpc: item.name => item
  }

  vpc_id = [for vpc in aws_vpc.main : vpc.id if vpc.tags.Name == each.value.name][0]

  tags = {
    Name = "${each.value.name}-internet-gateway"
  }
}

resource "aws_security_group" "main" {
  depends_on = [
    aws_vpc.main
  ]

  for_each = {
    for item in local.security_groups: item.name => item
  }

  name = each.value.name
  vpc_id = [for vpc in aws_vpc.main : vpc.id if vpc.tags.Name == each.value.vpc_id][0]

  dynamic "ingress" {
    for_each = each.value.ingress

    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = each.value.egress
    content {
      from_port = egress.value.from_port
      to_port = egress.value.to_port
      protocol = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = each.value.name
  }
}