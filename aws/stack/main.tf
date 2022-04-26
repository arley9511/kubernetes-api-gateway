module "vpc" {
  source = "./../services/network/vpc"

  vpc = var.vpc
}

module "subnet" {
  source = "./../services/network/subnets"

  depends_on = [module.vpc]

  vpc = var.vpc

  # using the outputs form the vpc to create the required subnets
  gateway_info = module.vpc.gateway_info
  vpc_info = module.vpc.vpc_info
}
