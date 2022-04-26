variable "vpc" {
  description = "The VPC configuration that contains all the subnets"

  type = list(object({
    name = string
    cidr_block = string
    instance_tenancy = string
    enable_dns_support = bool
    enable_dns_hostnames = bool
    subnets = list(object({
      name = string
      cidr_block = string
      availability_zone = string
    }))
    nat_gateways = list(object({
      name = string
      subnet = string
      elastic_ip = object({
        name = string
        vpc = bool
      })
    }))
    router_tables = list(object({
      name = string
      subnets = list(string)
      routes = list(object({
        cidr_block = string
        nat_gateway = string
        gateway_name = string
        vpc_peering_connection_id = string
      }))
    }))
    security_groups = list(object({
      name = string
      ingress = list(object({
        from_port = number
        to_port = number
        protocol = string
        cidr_blocks = list(string)
      }))
      egress = list(object({
        from_port = number
        to_port = number
        protocol = string
        cidr_blocks = list(string)
      }))
    }))
    acl = list(object({
      name = string
      subnets = list(string)
      egress = list(object({
        protocol = string
        rule_no = number
        action = string
        cidr_block = string
        from_port = number
        to_port = number
      }))
      ingress = list(object({
        protocol = string
        rule_no = number
        action = string
        cidr_block = string
        from_port = number
        to_port = number
      }))
    }))
  }))
}
