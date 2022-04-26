output "instances" {
  value = [for ec2 in module.ec2_instance: {
    id = ec2.id,
    name = ec2.tags_all.Name
  }]
}
