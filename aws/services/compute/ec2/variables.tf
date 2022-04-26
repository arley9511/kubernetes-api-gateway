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

variable "subnets" {
  type = list(object({
    subnet_id = string
    name = string
  }))
}

variable "security_groups" {
  type = list(object({
    id = string
    name = string
  }))
}
