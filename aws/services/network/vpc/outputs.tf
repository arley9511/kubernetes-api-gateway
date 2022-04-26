output "vpc_info" {
  value = [for vpc in aws_vpc.main: {vpc_id = vpc.id, name = vpc.tags.Name}]
}

output "gateway_info" {
  value = [for gateway in aws_internet_gateway.main: {id: gateway.id, vpc_id: gateway.vpc_id, name = gateway.tags.Name}]
}

output "security_groups" {
  value = [for sg in aws_security_group.main: {
    id = sg.id,
    name = sg.name
  }]
}
