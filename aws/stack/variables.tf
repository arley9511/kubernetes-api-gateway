variable "region" {
  description = "The region to apply the changes"
  type = string
}

variable "profile" {
  description = "The aws profile that contains the credentials for the aws project"
  type = string
}

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

variable "ec2" {
  description = "Configuration for launch ec2 instances"

  type = list(object({
    name = string
    ami = string
    instance_type = string
    key_name = string
    key_output = string
    monitoring = bool
    user_data_path = string
    vpc_security_group_ids = list(string)
    subnet_id = string
    tags = object({})
  }))
}

variable "s3_with_trigger" {
  description = ""

  type = list(object({
    topic_name = string
    buckets = list(string)
    events = string
  }))
}

variable "load_balancers" {
  description = ""

  type = list(object({
    name : string
    subnets : list(string)
    instances : list(string)
    security_groups = list(string)
    listeners : list(object({
      instance_port     = number
      instance_protocol = string
      lb_port           = number
      lb_protocol       = string
    }))
    health_checks = list(object({
      healthy_threshold   = number
      unhealthy_threshold = number
      timeout             = number
      target              = string
      interval            = number
    }))
    tags : object({})
  }))
}
