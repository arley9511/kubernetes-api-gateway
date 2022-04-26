locals {
  subnet = flatten([
    for vpc in var.vpc: [
      for subnet in vpc.subnets: {
        name = subnet.name
        cidr_block = subnet.cidr_block
        availability_zone = subnet.availability_zone

        vpc_id = [for i in range(length(var.vpc_info)): var.vpc_info[i].vpc_id if var.vpc_info[i].name == vpc.name][0]
      }
    ]
  ])
  acl = flatten([
    for vpc in var.vpc: [
      for acl in vpc.acl: {
        name = acl.name
        egress = acl.egress
        ingress = acl.ingress
        subnets = acl.subnets
        vpc_id = [for i in range(length(var.vpc_info)): var.vpc_info[i].vpc_id if var.vpc_info[i].name == vpc.name][0]
      }
    ]
  ])
  nat_gateways = flatten([
    for vpc in var.vpc: [
      for nat in vpc.nat_gateways: {
        name = nat.name
        subnet = nat.subnet
        elastic_ip = nat.elastic_ip
        vpc_id = [for i in range(length(var.vpc_info)): var.vpc_info[i].vpc_id if var.vpc_info[i].name == vpc.name][0]
      }
    ]
  ])
  router_tables = flatten([
    for vpc in var.vpc: [
      for router_table in vpc.router_tables: {
        name = router_table.name
        subnets = router_table.subnets
        routes = router_table.routes
        vpc_id = [for i in range(length(var.vpc_info)): var.vpc_info[i].vpc_id if var.vpc_info[i].name == vpc.name][0]
      }
    ]
  ])
  router_table_association = flatten([
    for vpc in var.vpc: [
      for router_table in vpc.router_tables: [
        for subnet in router_table.subnets: {
          unique_name = "${subnet}-association"
          subnet = subnet
          router_table = router_table.name
        }
      ]
    ]
  ])
}

resource "aws_subnet" "main" {
  for_each = {
    for item in local.subnet: item.name => item
  }

  vpc_id = each.value.vpc_id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.value.name
  }
}

resource "aws_network_acl" "main" {
  depends_on = [aws_subnet.main]

  for_each = {
    for item in local.acl: item.name => item
  }

  vpc_id = each.value.vpc_id
  subnet_ids = [for subnet in aws_subnet.main: subnet.id if contains(each.value.subnets, subnet.tags.Name)]

  dynamic "egress" {
    for_each = each.value.egress
    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  tags = {
    Name = each.value.name
  }
}

resource "aws_eip" "main" {
  depends_on = [
    aws_subnet.main
  ]

  for_each = {
    for item in local.nat_gateways: item.name => item
  }

  vpc = each.value.elastic_ip.vpc

  tags = {
    nat_gateway = each.value.name
    Name = each.value.elastic_ip.name
  }
}

resource "aws_nat_gateway" "main" {
  depends_on = [
    aws_eip.main
  ]

  for_each = {
    for item in local.nat_gateways: item.name => item
  }

  allocation_id = [for eip in aws_eip.main : eip.id if eip.tags.Name == each.value.elastic_ip.name][0]
  subnet_id = [for sub in aws_subnet.main : sub.id if sub.tags.Name == each.value.subnet][0]

  tags = {
    Name = each.value.name
    subnet = each.value.subnet
    elastic_ip = each.value.elastic_ip.name
  }
}

resource "aws_route_table" "main" {
  depends_on = [aws_nat_gateway.main]

  for_each = {
    for item in local.router_tables: item.name => item
  }

  vpc_id = each.value.vpc_id

  dynamic "route" {
    for_each = each.value.routes

    content {
      cidr_block = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway != "" ? [for ngt in aws_nat_gateway.main : ngt.id if ngt.tags.Name == route.value.nat_gateway][0] : ""
      vpc_peering_connection_id = route.value.vpc_peering_connection_id != "" ?  route.value.vpc_peering_connection_id : ""
      gateway_id = length([for gateway in var.gateway_info: gateway.id if gateway.name == route.value.gateway_name]) > 0 ? [for gateway in var.gateway_info: gateway.id if gateway.name == route.value.gateway_name][0] : ""
    }
  }

  tags = {
    Name = each.value.name
  }
}

resource "aws_route_table_association" "main" {
  depends_on = [aws_route_table.main]

  for_each = {
    for item in local.router_table_association: item.unique_name => item
  }

  subnet_id      = [for sub in aws_subnet.main : sub.id if sub.tags.Name == each.value.subnet][0]
  route_table_id = [for rt in aws_route_table.main : rt.id if rt.tags.Name == each.value.router_table][0]
}