output "subnets" {
  value = [for sub in aws_subnet.main: {
    subnet_id = sub.id,
    name = sub.tags.Name
  }]
}

output "elastic_ip" {
  value = [for eip in aws_eip.main: {
    subnet_id = eip.id,
    name = eip.tags.Name
  }]
}

output "nat_gateway" {
  value = [for nat in aws_nat_gateway.main: {
    subnet_id = nat.id,
    name = nat.tags.Name
  }]
}

output "route_table" {
  value = [for rt in aws_route_table.main: {
    subnet_id = rt.id,
    name = rt.tags.Name
  }]
}

output "route_table_association" {
  value = [for rt in aws_route_table_association.main: {
    subnet_id = rt.id
  }]
}
