locals {
  lb = flatten([
    for lb in var.load_balancers: {
      name = lb.name
      subnets = lb.subnets
      instances = lb.instances
      listeners = lb.listeners
      health_checks = lb.health_checks
      security_groups = lb.security_groups
      tags = lb.tags
    }
  ])
}

resource "aws_elb" "main" {
  for_each = {
    for item in local.lb: item.name => item
  }

  name = each.value.name

  security_groups = [for sg in var.security_groups: sg.id if contains(each.value.security_groups, sg.name)]

  subnets = [for subnet in var.subnets: subnet.subnet_id if contains(each.value.subnets, subnet.name)]

  dynamic "listener" {
    for_each = each.value.listeners
    content {
      instance_port     = listener.value.instance_port
      instance_protocol = listener.value.instance_protocol
      lb_port           = listener.value.lb_port
      lb_protocol       = listener.value.lb_protocol
    }
  }

  dynamic "health_check" {
    for_each = each.value.health_checks
    content {
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
      timeout             = health_check.value.timeout
      target              = health_check.value.target
      interval            = health_check.value.interval
    }
  }

  instances                   = [for instance in var.instances: instance.id if contains(each.value.instances, instance.name)]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = each.value.tags
}
