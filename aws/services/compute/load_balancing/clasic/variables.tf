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

variable "subnets" {
  type = list(object({
    subnet_id = string
    name = string
  }))
}

variable "instances" {
  type = list(object({
    id = string
    name = string
  }))
}

variable "security_groups" {
  type = list(object({
    id = string
    name = string
  }))
}
